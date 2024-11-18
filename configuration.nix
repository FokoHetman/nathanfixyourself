# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
# vim: ft=nix ts=2 sts=2 sw=2 et

inputs:
{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      # (builtins.fetchurl https://nathanlaptopv.axolotl-snake.ts.net/tailscale.nix)
      ./secrets.nix
      ./nginx.nix
      ./sso.nix
      ./ci.nix
    ];

  nix.settings = {
    experimental-features = ["nix-command" "flakes" "impure-derivations" "ca-derivations"];
    # substitute = false;
    keep-outputs = true;
    keep-derivations = true;
    trusted-users = ["root" "@wheel"];
    allow-unsafe-native-code-during-evaluation = true;
  };
  nixpkgs.config.allowUnfree = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_6_11;
  # boot.crashDump.enable = true;
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
    "kernel.sysrq" = 1;
  };

  # Use the systemd-boot EFI boot loader.
  # boot.loader.systemd-boot.enable = true;
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      device = "nodev";
      efiSupport = true;
      catppuccin.enable = true;
    };
  };
  systemd.services.reload-ssh-keys = {
    script = ''
      cp -rT /nix/persist2/ssh/ /etc/ssh/
    '';
    wantedBy = [ "multi-user.target" ];
  };

  swapDevices = [{ device = "/nix/swap"; }];
  environment.variables.EDITOR = "nvim";
  environment.etc = {
    "pacman.conf".text = ''
      ################################################################################
      ################# Arch Linux mirrorlist generated by Reflector #################
      ################################################################################
      
      # With:       reflector @/etc/xdg/reflector/reflector.conf
      # When:       2024-04-10 16:01:30 UTC
      # From:       https://archlinux.org/mirrors/status/json/
      # Retrieved:  2024-04-10 16:00:15 UTC
      # Last Check: 2024-04-10 15:51:59 UTC
      [core]
      Architecture = x86_64
      Server = https://mirror.theo546.fr/archlinux/$repo/os/$arch
      Server = https://mirror.ubrco.de/archlinux/$repo/os/$arch
      Server = https://mirror.cyberbits.eu/archlinux/$repo/os/$arch
      Server = https://mirror.osbeck.com/archlinux/$repo/os/$arch
      Server = https://archlinux.uk.mirror.allworldit.com/archlinux/$repo/os/$arch
      Server = https://mirror.f4st.host/archlinux/$repo/os/$arch
      Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
      Server = https://mirror.moson.org/arch/$repo/os/$arch
      Server = https://mirror.lty.me/archlinux/$repo/os/$arch
      Server = https://archlinux.thaller.ws/$repo/os/$arch
      Server = https://europe.mirror.pkgbuild.com/$repo/os/$arch
      Server = https://mirror.ufscar.br/archlinux/$repo/os/$arch
      Server = https://at.arch.mirror.kescher.at/$repo/os/$arch
      Server = https://america.mirror.pkgbuild.com/$repo/os/$arch
      Server = https://mirror.sunred.org/archlinux/$repo/os/$arch
      Server = https://mirror.telepoint.bg/archlinux/$repo/os/$arch
      Server = https://md.mirrors.hacktegic.com/archlinux/$repo/os/$arch
      Server = https://mirrors.neusoft.edu.cn/archlinux/$repo/os/$arch
      Server = https://archlinux.mailtunnel.eu/$repo/os/$arch
      Server = https://archlinux.za.mirror.allworldit.com/archlinux/$repo/os/$arch
    '';
  };

  networking = {
    hostName = "nathanlaptopv"; # Define your hostname.
    # Pick only one of the below networking options.
    # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
    wireless = {
      enable = true;
      networks = import ./networks.nix;
    };
    # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.
    nameservers = ["8.8.8.8" "8.8.4.4"];
    nftables.enable = true;
    firewall = {
      enable = false;
      allowedTCPPorts = [2423 2352 31337 6697];
      rejectPackets = true;
    };
    # TODO(PoolloverNathan): add adlists
    hosts = {
      "0.0.0.0" = ["api.hapara.com" "hl.hapara.com" "chromebook.ccpsnet.net" "h.pool.net.eu.org"];
      "192.168.1.4" = ["home.vscode.local"];
      "192.168.143.69" = ["roaming.vscode.local"];
    };
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    # keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;


  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  services = {
    postgresql = {
      enable = true;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
      '';
    };
    xserver = {
      enable = true;
      desktopManager.plasma5.enable = true;
      desktopManager.xfce.enable = true;
    };
    openssh.enable = true;
    openssh.settings = {
      X11Forwarding = true;
    };
    flatpak.enable = true;
    fprintd.enable = true;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    minecraft-server = {
      enable = true;
      eula = true;
      declarative = true;
      openFirewall = true;
      package = pkgs.minecraftServers.vanilla-1-20;
    };
    rsyncd.enable = true;
    # ircdHybrid = {
    #   enable = true;
    #   serverName = "Poolrc";
    #   description = "IRC server for PoolloverNathan's tailnet.";
    #   extraIPs = ["127.0.0.1"];
    # };
    ngircd.enable = true;
    ngircd.config = ''
      [OPTIONS]
      PAM = false
    '';
    jellyfin.enable = true;
    jellyfin.openFirewall = true;
    dnsmasq.enable = true;
    dnsmasq.settings = {
      # domain-needed = true;
      server = [
        "8.8.8.8"
        "8.8.4.4"
      ];
      # local = "home";
    };
  };
  security.rtkit.enable = true;
  specialisation = {
    wayland.configuration = {
      services = {
        xserver.enable = lib.mkForce false;
        hypridle.enable = true;
      };
      programs = {
        hyprland.enable = true;
        hyprlock.enable = true;
      };
    };
  };

  # security.pam.oath.enable = true;
  environment.etc."users.oath".text = ''
    
  '';

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  hardware.pulseaudio.enable = false;

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  # users.users.alice = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  #   packages = with pkgs; [
  #     firefox
  #     tree
  #   ];
  # };
  users.mutableUsers = false;
  users.users = {
    root = {
      uid = 0;
      extraGroups = ["wheel"];
    };
    sand = {
      uid = 1001;
      group = "sand";
      isSystemUser = true;
      packages = with pkgs; [
        nmap
      ];
      hashedPassword = "";
      home = "/var/sand";
    };
    foko = {
      uid = 1004;
      isNormalUser = true;
      # packages = import /home/foko/.config/pkgs.nix { inherit pkgs; };
      initialHashedPassword = "";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEgTxm0wBvRg8YSezwHvRYOhKT7G8lv5JtrlGNp5gkg7 foko@fokolaptop"
      ];
    };
    bunny = {
      uid = 1005;
      isNormalUser = true;
    };
    kai = {
      uid = 1022;
      isNormalUser = true;
      group = "users";
      extraGroups = ["wheel"];
      hashedPassword = "$y$j9T$rDEo4MR.C4ZzaBPXkpWEb.$FpdzrLaf4E8R.IhyXsdjSYQ6WObpHnQKO50a0mBpKb6";
    };
    blahai = {
      uid = 10667;
      isNormalUser = true;
      group = "users";
    };
    zoot = {
      uid = 10699;
      isNormalUser = true;
      group = "users";
    };
    nemmy = {
      uid = 1253;
      isNormalUser = true;
      group = "users";
      hashedPassword = "$y$j9T$laBYp0OM6ZMEg.FeGV4J20$MOSlQJA.XGo4SXsn7zUi5o3Y6SUp5tBhASDoTFMJ6j4";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKMh9MzUXUv/qhUUbUE8KMykreeGbwSDQk/YHPcTi0Wc panda@pandaptable.moe"
      ];
    };
  };
  users.groups.sand = {};
  users.groups.bunny = {};
  users.groups.ci = {};
  # {{{ Dedicated !neofetch user for security purposes —PoolloverNathan
  users.groups.neofetch.gid = 337;
  users.users.neofetch = {
    isSystemUser = true;
    uid = 337;
    home = "/var/neofetcher";
    createHome = true;
    shell = pkgs.neofetch + /bin/neofetch;
    group = "neofetch";
    openssh.authorizedKeys.keys = [
      ''ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIF+FPD+DCISuSH1dtBbdAB5C/WMmuTl7ZouGjQQ0cThc''
    ];
  };
  # }}} Dedicated !neofetch user for security purposes —PoolloverNathan

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = [
    pkgs.vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    pkgs.wget
    pkgs.git
    pkgs.screen
    pkgs.bashInteractive
    pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
    pkgs.ffmpeg
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  programs.nix-ld = {
    enable = true;
    libraries = [pkgs.glibc];
  };
  programs.git = {
    enable = true;
    lfs.enable = true;
    config = {
      safe.directory = "*";
    };
  };
  programs.steam.enable = true;

  # {{{ nrb = sudo nixos-rebuild
  # }}} nrb = sudo nixos-rebuild

  # List services that you want to enable:

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "23.11"; # Did you read the comment?

  home-manager.users.blahai.home.stateVersion = "23.11";
  home-manager.users.blahai.home.file.".ssh/authorized_keys".text = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILPbmiNqoyeKXk/VopFm2cFfEnV4cKCFBhbhyYB69Fuu";
}

