{
  description = "t7o.com — personal blog built with Zola";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    austere-theme = {
      url = "github:tomwrw/austere-theme-zola";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
      austere-theme,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        svg-fmt = pkgs.writeShellScriptBin "svg-fmt" ''
          for f in "$@"; do
            ${pkgs.libxml2}/bin/xmllint --format --output "$f" "$f"
          done
        '';

        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";

          programs.nixfmt.enable = true;
          programs.taplo.enable = true;
          programs.prettier.enable = true;

          # No HTML formatter: prettier mangles Tera tags and djlint isn't
          # idempotent on them. Format HTML templates by hand.
          settings.formatter.prettier.excludes = [ "*.html" ];

          settings.formatter.svg = {
            command = "${svg-fmt}/bin/svg-fmt";
            includes = [ "*.svg" ];
          };

          settings.global.excludes = [
            "flake.lock"
            "LICENSE*"
            "*.ico"
            "*.png"
            "public/**"
            ".nix-profile/**"
            ".direnv/**"
            "themes/**"
          ];
        };

        treefmt = treefmtEval.config.build.wrapper;

        devPackages = with pkgs; [
          zola
          treefmt
        ];

        refresh = pkgs.writeShellScriptBin "refresh" ''
          nix build .#packages.''${system}.dev-profile --out-link .nix-profile
        '';
      in
      {
        formatter = treefmt;

        packages.dev-profile = pkgs.buildEnv {
          name = "t7o-com-dev-profile";
          paths = devPackages ++ [ refresh ];
        };

        devShells.default = pkgs.mkShell {
          packages = devPackages ++ [ refresh ];

          shellHook = ''
            refresh
            export PATH="$PWD/.nix-profile/bin:$PATH"

            mkdir -p themes
            ln -sfn ${austere-theme} themes/austere
          '';
        };
      }
    );
}
