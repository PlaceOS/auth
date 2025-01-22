=begin
require "opentelemetry/sdk"
require "opentelemetry/exporter/otlp"
require "opentelemetry/instrumentation/all"

endpoint = ENV["OTEL_EXPORTER_OTLP_ENDPOINT"]
if endpoint
  OpenTelemetry::SDK.configure do |c|
    c.service_name = "auth"
    c.use_all # enables all instrumentation!
  end
end
=end
