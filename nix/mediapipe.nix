# https://github.com/NixOS/nixpkgs/pull/132275
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  python312,
  unzip,
  zip,
}:
let
  python = python312;
in
python.pkgs.buildPythonPackage rec {
  pname = "mediapipe";
  version = "0.10.18";
  format = "wheel";

  pyInterpreterVersion = "cp${builtins.replaceStrings [ "." ] [ "" ] python.pythonVersion}";

  src = fetchurl {
    # fetchPypi fails due to https://files.pythonhosted.org/packages/py2.py3/m/mediapipe/mediapipe-0.10.18-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl being a 404
    # see also https://github.com/NixOS/nixpkgs/issues/344218
    url = "https://files.pythonhosted.org/packages/e2/41/1a28b2d89238fe3aa011af3ea13897eccc6b89e4a9002045cd3f2af86b3d/mediapipe-0.10.18-cp312-cp312-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
    hash = "sha256-7bq/uXKNwfzZP+pHq+zhLUMwBTCh1CYeJX9r1OO+CdE=";
  };

  nativeBuildInputs = [
    unzip
    zip
    autoPatchelfHook
  ];

  postPatch = ''
    # Patch out requirement for static opencv so we can substitute it with the nix version
    METADATA=mediapipe-${version}.dist-info/METADATA
    unzip $src $METADATA
    substituteInPlace $METADATA \
      --replace "Requires-Dist: opencv-contrib-python" ""
    chmod +w dist/*.whl
    zip -r dist/*.whl $METADATA
  '';

  propagatedBuildInputs = with python.pkgs; [
    absl-py
    attrs
    matplotlib
    numpy
    opencv4
    protobuf
    six
    wheel
  ];

  pythonImportsCheck = [ "mediapipe" ];

  meta = with lib; {
    description = "Cross-platform, customizable ML solutions for live and streaming media";
    homepage = "https://mediapipe.dev/";
    license = licenses.asl20;
    maintainers = with maintainers; [ angustrau ];
    platforms = [
      "x86_64-linux"
      "x86_64-darwin"
    ];
  };
}
