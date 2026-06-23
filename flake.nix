{
  description = "Hack The Box flake [.#full .#burp .#reverse .#automation or .#master-*]";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    burpsuitepro = {
      url = "github:xiv3r/Burpsuite-Professional";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-master
    , burpsuitepro
    ,
    }:
    let
      system = "x86_64-linux";
      burpPackage = burpsuitepro.packages.${system}.default;

      mkPkgs =
        input:
        import input {
          inherit system;
          config.allowUnfree = true;
        };

      mkShellHook = title: pkgList: extra: ''
        printf "\n"
        printf "\033[1;36m[ \033[1;33m${title}\033[1;36m ]\033[0m\n"
        printf "\033[2m─────────────────────────────\033[0m\n"
        ${builtins.concatStringsSep "\n" (
          map (p: "printf \"  \\033[1;32m+\\033[0m ${p.name}\\n\"") pkgList
        )}
        printf "\033[2m─────────────────────────────\033[0m\n\n"
        ${extra}
        exec nu
      '';

      mkCombined =
        pkgs: name: pkgLists: extra:
        let
          allPkgs = builtins.concatLists pkgLists;
        in
        pkgs.mkShell {
          packages = allPkgs;
          buildInputs = [ pkgs.fontconfig ];
          shellHook = mkShellHook name allPkgs extra;
        };

      mkShells =
        pkgs:
        let
          fontHook = ''
            export FONTCONFIG_FILE=${pkgs.fontconfig.out}/etc/fonts/fonts.conf
          '';
          shellList = builtins.concatStringsSep "\n" (
            map (name: "printf \"  \\033[1;32m->\\033[0m \\033[1m${name}\\033[0m\\n\"") (
              builtins.attrNames (mkShells pkgs)
            )
          );
        in
        {
          # to add a shell:
          # myShell = mkCombined pkgs "myShell" [ (basePackages pkgs) (myPackages pkgs) ] "";
          # to combine with existing:
          # myShell = mkCombined pkgs "myShell" [ (basePackages pkgs) (myPackages pkgs) [ burpPackage ] ] fontHook;

          default = mkCombined pkgs "default" [ (basePackages pkgs) ] ''
            printf "\033[1;33m  shells:\033[0m\n"
            ${shellList}
            printf "\n\033[2m  prefix master- for master channel (gets a lot of new patches)\033[0m\n"
          '';

          burp = mkCombined pkgs "burp" [
            (basePackages pkgs)
            [ burpPackage ]
          ]
            fontHook;

          reverse = mkCombined pkgs "reverse-engineering" [
            (basePackages pkgs)
            (reversePackages pkgs)
          ] "printf '[+] Loaded reversing environment\n'";

          automation = mkCombined pkgs "automation" [
            (basePackages pkgs)
            (automationPackages pkgs)
          ] "printf '[+] Loaded msf, wpscan and netexec\n'";

          full = mkCombined pkgs "full" [
            (basePackages pkgs)
            [ burpPackage ]
            (reversePackages pkgs)
            (automationPackages pkgs)
          ]
            fontHook;
        };

      basePackages =
        pkgs: with pkgs; [
          nushell
          openvpn
          nmap
          hashcat
          ffuf
          inetutils
          exploitdb
          gobuster
          whois
          dig
          wget
        ];

      automationPackages =
        pkgs: with pkgs; [
          metasploit
          wpscan
          netexec
        ];

      reversePackages =
        pkgs: with pkgs; [
          cutter
          pince
        ];

      prefixAttrs =
        prefix: attrs: nixpkgs.lib.mapAttrs' (k: v: nixpkgs.lib.nameValuePair "${prefix}-${k}" v) attrs;

    in
    {
      devShells.${system} =
        mkShells (mkPkgs nixpkgs) // prefixAttrs "master" (mkShells (mkPkgs nixpkgs-master));
    };
}
