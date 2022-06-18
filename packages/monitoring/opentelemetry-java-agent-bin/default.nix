{ fetchurl }:

fetchurl rec {
  name = "opentelemetry-java-agent-${meta.version}.jar";
  meta.version = "1.15.0";
  url = "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${meta.version}/opentelemetry-javaagent.jar";
  sha256 = "sha256-FoHax7pS3ohZ70TCKVkGsAONDmr4/FFjY5SSoCfySy0=";
}
