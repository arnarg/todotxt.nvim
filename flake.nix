{
  description = "Neovim plugin to view and add tasks stored in a todo.txt format";

  inputs = {
    utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-21.11";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages."${system}";
        currDir = builtins.getEnv "PWD";
      in rec {
        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs; [
            luajit
            luajitPackages.busted
            luajitPackages.luacheck
          ];
          LUA_PATH = "${currDir}/lua/?.lua;${currDir}/lua/?/init.lua";
        };
      }
    );
}
