{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pyprojectVersionPatchHook,
  setuptools,
  aiohttp,
  pydantic,
  yarl,
  codespell,
  mypy,
  pre-commit,
  pre-commit-hooks,
  pytest,
  pytest-asyncio,
  pytest-cov,
  ruff,
  nix-update-script,
}:

buildPythonPackage (finalAttrs: {
  pname = "deezer-python-gql";
  version = "0.25.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "music-assistant";
    repo = "deezer-python-gql";
    tag = "v${finalAttrs.version}";
    hash = "sha256-D0F6mXoL4xjEUOoyo0BNecnfmJt+QNFadFSks0f5apE=";
  };

  build-system = [
    setuptools
  ];

  dependencies = [
    aiohttp
    pydantic
    yarl
  ];

  optional-dependencies = {
    test = [
      codespell
      mypy
      pre-commit
      pre-commit-hooks
      pytest
      pytest-asyncio
      pytest-cov
      ruff
    ];
  };

  pythonImportsCheck = [
    "deezer_python_gql"
  ];

  nativeBuildInputs = [ pyprojectVersionPatchHook ];

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Unofficial python library for the Deezer GraphQL based API";
    homepage = "https://github.com/music-assistant/deezer-python-gql";
    changelog = "https://github.com/music-assistant/deezer-python-gql/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ kraftnix ];
  };
})

