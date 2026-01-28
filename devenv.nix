{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:

{
  packages = with pkgs; [ zenn-cli ];

  processes.preview.exec = "${pkgs.zenn-cli}/bin/zenn preview";
}
