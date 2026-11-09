{ stdenv
, cmake
, fcitx5
,
}:

stdenv.mkDerivation {
  pname = "fcitx5-status";
  version = "1.0.0";

  src = ./.;

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    fcitx5
  ];

  meta = {
    description = "Event-driven Fcitx5 input method status bridge";
  };
}
