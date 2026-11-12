{
  buildPythonPackage,
  fetchurl,
  hatchling,
  aiohttp-retry,
  ...
}:
buildPythonPackage {
  pname = "hindsight-client";
  version = "1.2.1";
  pyproject = true;

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/ba/83/a9626ebeb43c0bd03d5173adc31ea3e2e7a32939ef1043dff435fa3cd913/hindsight_client-1.2.1.tar.gz";
    hash = "sha256-JRxUX6KJCZfbTlxEfC2XHfQzOnOhzmBWCuXqvH/iMQY=";
  };

  build-system = [ hatchling ];

  # Everything but aiohttp-retry (aiohttp, pydantic, dateutil, typing-extensions,
  # urllib3, yarl, six) is already in hermes' sealed venv; redeclaring it trips
  # the plugin/core collision gate in extraPythonPackages.
  dependencies = [ aiohttp-retry ];

  dontCheckRuntimeDeps = true;
  doCheck = false;

  meta = {
    description = "Python client for Hindsight long-term memory";
    homepage = "https://github.com/vectorize-io/hindsight";
  };
}
