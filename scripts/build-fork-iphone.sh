#!/usr/bin/env bash
set -euo pipefail

cd apps/mobile
output="$RUNNER_TEMP/iphone-package"
mkdir -p "$output"

shopt -s nullglob
workspaces=(ios/*.xcworkspace)
projects=(ios/*.xcodeproj)
if (( ${#workspaces[@]} != 1 || ${#projects[@]} != 1 )); then
  echo 'Expected one generated iOS application project and workspace.' >&2
  exit 1
fi
scheme=$(basename "${workspaces[0]}" .xcworkspace)
args=(-workspace "${workspaces[0]}" -scheme "$scheme" -configuration Release
  -destination 'generic/platform=iOS' COMPILER_INDEX_STORE_ENABLE=NO)

if [[ -z "${IOS_DISTRIBUTION_CERTIFICATE_P12:-}${IOS_DISTRIBUTION_CERTIFICATE_PASSWORD:-}${IOS_PROVISIONING_PROFILE:-}" ]]; then
  derived="$RUNNER_TEMP/iphone-derived-data"
  xcodebuild "${args[@]}" -derivedDataPath "$derived" CODE_SIGNING_ALLOWED=NO build
  apps=("$derived"/Build/Products/Release-iphoneos/*.app)
  if (( ${#apps[@]} != 1 )); then
    echo 'Expected one arm64 iPhone application.' >&2
    exit 1
  fi
  staging=$(mktemp -d "$RUNNER_TEMP/iphone-payload.XXXXXXXX")
  mkdir "$staging/Payload"
  ditto "${apps[0]}" "$staging/Payload/$(basename "${apps[0]}")"
  (cd "$staging" && ditto -c -k Payload "$output/Agent-Desk-iphone-arm64-unsigned.ipa")
  echo 'signing=unsigned' >> "$GITHUB_OUTPUT"
  echo 'Built an unsigned device IPA. Installation requires Apple signing.' >> "$GITHUB_STEP_SUMMARY"
  exit 0
fi

: "${IOS_DISTRIBUTION_CERTIFICATE_P12:?Set the distribution certificate and provisioning profile together}"
: "${IOS_PROVISIONING_PROFILE:?Set the distribution certificate and provisioning profile together}"

signing_dir=$(mktemp -d "$RUNNER_TEMP/iphone-signing.XXXXXXXX")
keychain="$signing_dir/ios-signing.keychain-db"
password=$(openssl rand -hex 24)
echo "::add-mask::$password"
profile_path=''
cleanup_signing() {
  if [[ -n "$profile_path" ]]; then rm -f "$profile_path"; fi
  security delete-keychain "$keychain" 2>/dev/null || true
  rm -rf "$signing_dir"
}
trap cleanup_signing EXIT
umask 077
printf '%s' "$IOS_DISTRIBUTION_CERTIFICATE_P12" | base64 -D > "$signing_dir/certificate.p12"
printf '%s' "$IOS_PROVISIONING_PROFILE" | base64 -D > "$signing_dir/profile.mobileprovision"
security cms -D -i "$signing_dir/profile.mobileprovision" -o "$signing_dir/profile.plist"
plist_read() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$signing_dir/profile.plist"
}
profile_id=$(plist_read UUID)
team=$(plist_read TeamIdentifier:0)
app_id="$T3CODE_IOS_PERSONAL_TEAM_BUNDLE_ID"
if [[ "$(plist_read Entitlements:application-identifier)" != "$team.$app_id" ]] || ! plist_read ProvisionedDevices:0 >/dev/null; then
  echo "Use an ad hoc provisioning profile for $app_id with registered iPhones." >&2
  exit 1
fi
profile_dir="$HOME/Library/Developer/Xcode/UserData/Provisioning Profiles"
mkdir -p "$profile_dir"
profile_path="$profile_dir/$profile_id.mobileprovision"
cp "$signing_dir/profile.mobileprovision" "$profile_path"

security create-keychain -p "$password" "$keychain"
security set-keychain-settings -lut 21600 "$keychain"
security unlock-keychain -p "$password" "$keychain"
security import "$signing_dir/certificate.p12" -k "$keychain" \
  -P "${IOS_DISTRIBUTION_CERTIFICATE_PASSWORD:-}" -T /usr/bin/codesign
security set-key-partition-list -S apple-tool:,apple: -s -k "$password" "$keychain" >/dev/null
security list-keychains -d user -s "$keychain" "$HOME/Library/Keychains/login.keychain-db"
identity=$(security find-identity -v -p codesigning "$keychain" | awk '$0 ~ /Apple Distribution:/ {print $2; exit}')
if [[ -z "$identity" ]]; then
  echo 'The certificate does not contain a valid Apple Distribution signing identity.' >&2
  exit 1
fi

# Apply the provisioning profile only to the app target. Pods have their own signing settings.
ruby -rxcodeproj - "${projects[0]}" "$team" "$profile_id" "$identity" <<'RUBY'
project = Xcodeproj::Project.open(ARGV[0])
target = project.targets.find { |entry| entry.product_type == 'com.apple.product-type.application' }
abort 'Generated iOS app target is missing' unless target
release = target.build_configurations.find { |entry| entry.name == 'Release' }
abort 'Generated Release configuration is missing' unless release
release.build_settings.merge!({
  'CODE_SIGN_STYLE' => 'Manual',
  'DEVELOPMENT_TEAM' => ARGV[1],
  'PROVISIONING_PROFILE_SPECIFIER' => ARGV[2],
  'CODE_SIGN_IDENTITY' => ARGV[3],
})
project.save
RUBY

archive="$RUNNER_TEMP/AgentDesk.xcarchive"
xcodebuild "${args[@]}" -archivePath "$archive" archive

export_options="$signing_dir/export.plist"
plutil -create xml1 "$export_options"
plutil -insert method -string release-testing "$export_options"
plutil -insert signingStyle -string manual "$export_options"
plutil -insert signingCertificate -string "$identity" "$export_options"
plutil -insert teamID -string "$team" "$export_options"
plutil -insert provisioningProfiles -dictionary "$export_options"
/usr/libexec/PlistBuddy -c "Add :provisioningProfiles:$app_id string $profile_id" "$export_options"
xcodebuild -exportArchive -archivePath "$archive" -exportPath "$output" -exportOptionsPlist "$export_options"
echo 'signing=adhoc' >> "$GITHUB_OUTPUT"
echo 'Built an ad hoc IPA for the iPhones registered in the provisioning profile.' >> "$GITHUB_STEP_SUMMARY"
