{ writeShellApplication, bc, gnused, sane-backends, ... }:
writeShellApplication {
  name = "scanbook";
  runtimeInputs = [
    bc
    gnused
    sane-backends
  ];
  text = ./scanbook.sh;
}
