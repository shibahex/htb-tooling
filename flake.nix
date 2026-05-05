{
  description = "Hack The Box flake [.#full .#burp or .#master-default .#master-full]";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    burpsuitepro = {
      url = "github:xiv3r/Burpsuite-Professional";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-master, burpsuitepro }:
    let
      system = "x86_64-linux";
      burpPackage = burpsuitepro.packages.${system}.default;

      mkPkgs = input: import input {
        inherit system;
        config.allowUnfree = true;
      };

      mkShells = pkgs: {
        default = pkgs.mkShell {
          packages = basePackages pkgs;
        };
        burp = pkgs.mkShell {
          packages = basePackages pkgs ++ [ burpPackage ];
          buildInputs = [ pkgs.fontconfig ];
          shellHook = ''
            export FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf
          '';
        };
      } // { full = (mkShells pkgs).burp; };

      basePackages = pkgs: with pkgs; [
        openvpn nmap nushell sqlite hashcat
        unzip awscli2 ffuf inetutils
      ] ++ frameworks pkgs;

      frameworks = pkgs: with pkgs; [
        metasploit wpscan netexec
      ];

      prefixAttrs = prefix: attrs:
        nixpkgs.lib.mapAttrs' (k: v:
          nixpkgs.lib.nameValuePair "${prefix}-${k}" v
        ) attrs;

    in
    {
      devShells.${system} =
        mkShells (mkPkgs nixpkgs) //
        prefixAttrs "master" (mkShells (mkPkgs nixpkgs-master));
    };
}
