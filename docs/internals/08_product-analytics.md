# Product analytics

The server provides [`AnalyticsService`](../../apps/server/src/telemetry/AnalyticsService.ts) as a
local service that declines all reports. The service never initializes an installation identity,
reads provider credentials, queues events, or creates an HTTP client. Instrumentation can still be
exercised with in-memory test services. Feedback storage uses the declined result to mark reports
as unsent.

WebSocket connection metadata carries no analytics account or device identifier. Client and
server runtimes use local tracing for T3 Connect operations. The separate user-configured
OpenTelemetry export is described in [Telemetry and diagnostics](../user/telemetry.md).
