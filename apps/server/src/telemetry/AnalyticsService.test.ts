import { assert, it } from "@effect/vitest";
import * as ConfigProvider from "effect/ConfigProvider";
import * as Effect from "effect/Effect";
import * as AnalyticsService from "./AnalyticsService.ts";

it.effect("does not accept telemetry even when explicitly enabled in the environment", () =>
  Effect.gen(function* () {
    const analytics = yield* AnalyticsService.AnalyticsService;
    assert.isFalse(yield* analytics.record("server.boot.heartbeat", { projectCount: 1 }));
    assert.isFalse(yield* analytics.record("agent.feedback", { subject: "Local feedback" }));
  }).pipe(
    Effect.provide(AnalyticsService.layer),
    Effect.provide(
      ConfigProvider.layer(ConfigProvider.fromEnvRecord({ T3CODE_TELEMETRY_ENABLED: "true" })),
    ),
  ),
);
