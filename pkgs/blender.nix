# Blender carrying the native python deps our addons import; addons themselves are installed through Blender's UI.
{
  stdenv,
  fetchurl,
  autoPatchelfHook,
  symlinkJoin,
  makeWrapper,
  blender,
}: let
  ps = blender.pythonPackages;

  wheel = args:
    ps.buildPythonPackage (args
      // {
        format = "wheel";
        nativeBuildInputs = [autoPatchelfHook];
        buildInputs = [stdenv.cc.cc.lib];
        dontStrip = true;
      });

  # robust-weight-transfer crashes blender on 1.1.0, upstream constrains to 1.0.0
  robust-laplacian = wheel {
    pname = "robust_laplacian";
    version = "1.0.0";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/9c/2e/6f6ee63e9477794e22be513c1494996023a5f344d8a3944a2cacd0c008b0/robust_laplacian-1.0.0-cp313-cp313-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
      hash = "sha256-Zg8W291MpReXtYOvUe60ptZzqMjzYTtMsEm8xao7jsI=";
    };
    propagatedBuildInputs = [ps.numpy];
  };

  libigl = wheel {
    pname = "libigl";
    version = "2.6.1";
    src = fetchurl {
      url = "https://files.pythonhosted.org/packages/9c/5c/bc7aec8d3a93ce700dd6644c771a22fe6aff00379f7c97073f65a29270e8/libigl-2.6.1-cp312-abi3-manylinux_2_27_x86_64.manylinux_2_28_x86_64.whl";
      hash = "sha256-j9SPhnZj33/QUkRMEOsfocMDrMhuQBYGeXK0qrCuRYg=";
    };
    propagatedBuildInputs = [ps.numpy ps.scipy];
  };

  env = ps.python.withPackages (_: [ps.scipy robust-laplacian libigl]);
in
  # blender.withPackages can't be used here: it reads pkgs.blender internally, so overriding
  # blender with it recurses. Wrapping in place also keeps man pages and the thumbnailer.
  symlinkJoin {
    inherit (blender) name meta;
    paths = [blender];
    nativeBuildInputs = [makeWrapper];
    postBuild = ''
      wrapProgram $out/bin/blender --prefix PYTHONPATH : ${env}/${ps.python.sitePackages}
    '';
  }
