final: prev: {
  py-multibase = prev.py-multibase.overridePythonAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [
      final.pytestrunner
    ];
  });
}