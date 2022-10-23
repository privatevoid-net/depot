{ fetchurl }:

fetchurl rec {
  name = "opentelemetry-java-agent-${meta.version}.jar";
  meta.version = "1.19.1";
  url = "https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v${meta.version}/opentelemetry-javaagent.jar";
  sha256 = "sha256-f1kc0eqBrK+QmlRaZRiJq5OAKa2wrtTyLeBN8uK6698=";
}
