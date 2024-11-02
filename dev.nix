{ config, pkgs, ... }:
{

  environment.systemPackages = with pkgs; [
    vscode
    nixfmt-rfc-style

    jetbrains.idea-ultimate
    git
    gh
    docker
    jdk11
    jdk22
    maven
    nodejs_18
    nodePackages.vercel
    ghidra

  ];
}