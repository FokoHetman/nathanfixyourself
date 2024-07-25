{
  description = "NixOS configuration";

  inputs = {
    catppuccin.url = github:catppuccin/nix;
    catppuccin-qt5ct.url = github:catppuccin/qt5ct;
    catppuccin-qt5ct.flake = false;
    fokquote.url = github:fokohetman/fok-quote;
    home-manager.url = github:nix-community/home-manager;
    # nethack.url = git+ssh://nathanlaptopv/home/nathan/stuff/nethack;
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    nixvim.url = github:nix-community/nixvim;
    sadan4.url = github:sadan4/dotfiles;
    bunny.url = github:TheBunnyMan123/nixos-config;
  };

  outputs = inputs@{ self, nixpkgs, fokquote, home-manager, ... }: rec {
    # formatter = builtins.mapAttrs (system: pkgs: pkgs.nixfmt-rfc-style)
    mkNathan = canSudo: defineUser {
      uid = 1471;
      name = "nathan";
      inherit canSudo;
      userConfigFile = user/nathan;
      extraUserConfig.linger = true;
      extraConfigArgs = inputs;
      imports = [
        ({ pkgs, ... }: {
          systemd.services.nathan-setup = {
            enable = true;
            path = with pkgs; [bash coreutils];
            wantedBy = ["multi-user.target"];
            script = ''
              set -e
              cd /home/nathan
              mkdir -p .local/privbin
              chown nathan . .local $_
              chmod 0700 $_
              cd $_
              rm -rf setpriv
              cp ${pkgs.util-linux}/bin/setpriv .
              chown root setpriv
              chmod 4555 setpriv
            '';
          };
        })
      ];
    };
    nixosModules = {
      nathan = mkNathan true;
      nathan-nosudo = mkNathan false;
    };
    nixosConfigurations = {
      nathanlaptopv = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          (import ./configuration.nix inputs)
          inputs.catppuccin.nixosModules.catppuccin
          home-manager.nixosModules.home-manager
          nixosModules.nathan
	  # inputs.bunny.nixosModules.bunny-sshworthy
          (mkTailnet {
            ssh = false;
	    extraFlags = ["--no-accept-dns"];
          })
        ];
      };
    };
    defineUser = {
      uid,
      name,
      canSudo ? false,
      extraUserConfig ? {},
      userConfigFile ? null,
      extraHomeConfig ? {},
      extraConfigArgs ? {},
      imports ? [],
    }: args@{
      pkgs,
      lib,
      config,
      options,
      ...
    }:
    assert lib.assertMsg (extraConfigArgs != {} -> userConfigFile != null) "Cannot pass arguments to an unspecified config file";
    {
      inherit imports;
      config = let
        systemConfig = config.home-manager.users.${name}.system;
      in {
        users.users.${name} = {
          isNormalUser = !extraUserConfig.isSystemUser or false;
          inherit uid;
          extraGroups = if canSudo then lib.mkOverride (-100) ["wheel"] else [];
          inherit (systemConfig) shell hashedPassword;
          description = systemConfig.userDescription;
        } // extraUserConfig;
        home-manager.users.${name} = {
          options.system = {
            hashedPassword = lib.mkOption {
              description = ''
                The hash of your password. To generate a password hash, run `mkpasswd`. In most simple cases, you can also use `nixos passwd` to change your password.
                '';
              type = lib.types.nullOr (lib.types.passwdEntry lib.types.singleLineStr);
              default = null;
            };
            shell = lib.mkOption {
              description = ''
                Your default shell, to be used when logging in. Can be either a derivation (for `nix run`-like behavior) or a path (to run directly). If you pass a derivation that refers to an executable file directly, as opposed to the more common derivation with a `bin` directory, explicitly select `.outPath`.
                '';
              type = lib.types.pathInStore;
              default = pkgs.bashInteractive + /bin/bash;
            };
            userDescription = lib.mkOption {
              description = ''
                The description to give your user. This can be e.g. a longer or more common username.
                '';
              type = lib.types.passwdEntry lib.types.singleLineStr;
              default = "";
            };
            sshKeys = lib.mkOption {
              description = ''
                Public keys to allow SSH authorization for. If some are set, it will be legal to leave the password unspecified.
                '';
              type = with lib.types; listOf singleLineStr;
              default = [];
            };
          };
          imports = [
            extraHomeConfig
            (if userConfigFile != null then import userConfigFile (args // extraConfigArgs) else {})
          ];
          config.assertions = [
            {
              assertion = systemConfig.sshKeys != [] || systemConfig.hashedPassword != null;
              message = "User ${name} [${uid}] has no way to log in";
            }
          ];
        };
      };
    };
    mkTailnet = {
      hostname   ? null,
      ssh        ? true,
      extraFlags ? [],
      container  ? null,
      exitNode   ? true,
      tunnelPort ? 41641,
    }: let
      config = {
        services.tailscale = {
          enable = true;
          port = tunnelPort;
          openFirewall = true;
          extraUpFlags =
            (
              if ssh then
                ["--ssh"]
              else
                []
            ) ++ (
              if exitNode == true then
                ["--advertise-exit-node"]
              else if exitNode == null || exitNode == false then
                []
              else
                ["--exit-node=${exitNode}"]
            ) ++ (
              if hostname != null then
                ["--hostname=${hostname}"]
              else
                []
            ) ++ extraFlags;
          authKeyFile = builtins.toFile "tailscale-auth-key" "tskey-auth-kUMZpfCYXF11CNTRL-D2Rz24arzyQEirrNuLgT1RiCDH4Lw8fz";
        };
      };
    in if container == null then
      config
    else {
      containers.${container} = config;
    };
    packages = builtins.foldl' nixpkgs.lib.recursiveUpdate {} (builtins.map (att: {
      ${nixosConfigurations.${att}.pkgs.system}.${att} = nixosConfigurations.${att}.config.system.build;
    }) (builtins.attrNames nixosConfigurations));
  };
}
