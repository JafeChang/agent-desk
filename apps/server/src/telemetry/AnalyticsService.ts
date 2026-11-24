import * as Context from "effect/Context";
import * as Effect from "effect/Effect";
import * as Layer from "effect/Layer";

export class AnalyticsService extends Context.Service<
  AnalyticsService,
  {
    readonly record: (
      event: string,
      properties?: Readonly<Record<string, unknown>>,
    ) => Effect.Effect<boolean>;
  }
>()("t3/telemetry/AnalyticsService") {}

// Local builds never queue or send product analytics, including agent feedback.
export const layer = Layer.succeed(
  AnalyticsService,
  AnalyticsService.of({ record: () => Effect.succeed(false) }),
);
