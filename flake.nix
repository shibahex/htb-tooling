{
  description = "Hack The Box flake [.#full .#burp]";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Optional burp shell will use this
    burpsuitepro = {
      url = "github:xiv3r/Burpsuite-Professional";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      burpsuitepro,
    }:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Core CLI tooling (lightweight)
      basePackages = with pkgs; [
        openvpn
        nmap
        nushell
        sqlite
        hashcat
        unzip
        awscli2
        ffuf

      ## from pentesting in nutshell on HTB academy
      metasploit
      # ftp etc.
      inetutils
      # word press
      wpscan
      ];

      # Burp package (only used in specific shells)
      burpPackage = burpsuitepro.packages.${system}.default;
    in
    {
      devShells.${system} = {

        # Default HTB shell (recommended everyday shell)
        default = pkgs.mkShell {
          packages = basePackages;
        };

        # Web testing shell (adds Burp)
        burp = pkgs.mkShell {
          packages = basePackages ++ [ burpPackage ];

          buildInputs = with pkgs; [
            fontconfig
          ];

          shellHook = ''
            export FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf
          '';
        };

        # Everything included
        full = pkgs.mkShell {
          packages = basePackages ++ [ burpPackage ];

          buildInputs = with pkgs; [
            fontconfig
          ];

          shellHook = ''
            export FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf
          '';
        };
      };
    };
}
