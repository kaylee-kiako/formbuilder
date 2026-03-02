{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    systems = [
      "x86_64-linux"
    ];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    devShells = forAllSystems (
      system: let
        pkgs = import nixpkgs {inherit system;};
      in
        with pkgs; {
          default = mkShell {
            name = "Typst";

            nativeBuildInputs = [
              deno
              tinymist
              typst
              typstyle
              yarn
            ];

            buildInputs = [
              deno
              typst
            ];

            # Helps compilers. Fails unless the environment is '--impure'.
            TYPST_ROOT = builtins.getEnv "PWD";

            shellHook = ''
              unset SOURCE_DATE_EPOCH
            '';
          };
        }
    );
  };
}
