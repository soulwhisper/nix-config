{
  buildPythonPackage,
  fetchurl,
  setuptools,
  ...
}:
buildPythonPackage {
  pname = "aiohttp-retry";
  version = "2.9.1";

  src = fetchurl {
    url = "https://files.pythonhosted.org/packages/9d/61/ebda4d8e3d8cfa1fd3db0fb428db2dd7461d5742cea35178277ad180b033/aiohttp_retry-2.9.1.tar.gz";
    hash = "sha256-jrdekE7U7lwuwkL+/oW/BCQPaFORxIedj1QdYCj/AfE=";
  };

  # Runtime dep aiohttp comes from hermes' sealed venv; declaring it here would
  # trip the plugin/core collision gate in extraPythonPackages.
  dependencies = [ ];

  dontCheckRuntimeDeps = true;
  pyproject = true;
  build-system = [ setuptools ];

  doCheck = false;

  meta = {
    description = "Retry policy for aiohttp";
    homepage = "https://github.com/inyutin/aiohttp_retry";
  };
}
