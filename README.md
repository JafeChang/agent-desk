# Agent Desk

Agent Desk is an unofficial fork of [T3 Code](https://github.com/pingdotgg/t3code) for running
coding agents on your own machines. It is independent of T3 Tools, Inc.

The fork removes product analytics, cross-account telemetry identifiers, and T3 Connect relay
tracing. See [Telemetry and diagnostics](docs/user/telemetry.md) for the data flows and controls.

## Packages

[GitHub Releases](https://github.com/JafeChang/agent-desk/releases) has Apple silicon and Intel DMGs,
a Linux x64 AppImage and Debian package, and a Windows x64 installer with the Linux WSL runtime.
[GitHub Actions](https://github.com/JafeChang/agent-desk/actions/workflows/fork-build.yml) also
provides the Linux CLI archive and iPhone build. Desktop preview packages have no update feed.

The first macOS preview was built without Developer ID signing or notarization. A downloaded copy
can trigger a macOS security alert. For a notarized DMG, run **Fork packages** with target
`macos-notarized` after configuring `CSC_LINK` (base64 Developer ID Application `.p12`),
`CSC_KEY_PASSWORD`, `APPLE_API_KEY` (App Store Connect `.p8` contents), `APPLE_API_KEY_ID`, and
`APPLE_API_ISSUER` in GitHub Actions secrets. The workflow verifies the mounted app with
`codesign`, `stapler`, and macOS distribution assessment before upload.

The iPhone artifact targets physical arm64 devices. A run with no signing configuration produces
an unsigned IPA. For ad hoc installation on registered iPhones, set the `IOS_BUNDLE_IDENTIFIER`
repository variable and the `IOS_DISTRIBUTION_CERTIFICATE_P12`,
`IOS_DISTRIBUTION_CERTIFICATE_PASSWORD`, and `IOS_PROVISIONING_PROFILE` Actions secrets. The
certificate and profile contents use base64. The profile must match the bundle ID and list the
registered iPhones.

## Documentation

- [Install and first run](./docs/user/install.md)
- [Remote access from a phone or another machine](./docs/user/remote-access.md)
- [Permission modes](./docs/user/permission-modes.md)
- [Source control](./docs/user/source-control.md)
- [Connect outside agents over MCP](./docs/user/outside-agents.md)
- [FAQ](./docs/user/faq.md)

[All docs](./docs/README.md) has the full list.

## Contributing

We have limited review capacity. Small, focused fixes are the most likely to be merged. Features need an approved discussion first.

- Read [CONTRIBUTING.md](./CONTRIBUTING.md) before you report a bug or open a pull request.
- Put feature requests in [Ideas](https://github.com/pingdotgg/t3code/discussions/categories/ideas).
- Build from source with the [development runbook](./docs/operations/00_development.md#first-checkout). The [architecture overview](./docs/internals/01_architecture.md) explains how it works.
- Get help in [Discord](https://discord.gg/jn4EGJjrvv).

## License

The source code in this repository is licensed under the [MIT License](./LICENSE).

## Trademarks and forks

The MIT license applies **only to the source code**. It does not grant any rights to T3 Tools, Inc.'s trademarks, branding, or trade dress, including the **T3 Code** name, wordmark, logos, and application icons.

If you fork, redistribute, or build on T3 Code's source code:

- **Use your own branding.** Replace the T3 Code name, wordmark, logos, and application icons in any public fork, redistributed build, website, package, or app store listing.
- **Be explicitly clear that your project is unofficial.** Do not use the T3 Code name, wordmark, logo, or branding in your own projects without making it unmistakably clear that your project is unofficial and not affiliated with or endorsed by T3 Tools, Inc.

Using our name, wordmark, logo, or branding in a way that suggests official status or affiliation is trademark infringement and unlawful. **Any project indicating or implying that it is an official version of T3 Code when it is not will be pursued to the full extent of the law.**

See [TRADEMARK.md](./TRADEMARK.md) for the full trademark and branding policy.
