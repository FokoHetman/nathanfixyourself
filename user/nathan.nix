# vim: ts=2 sts=2 sw=2 et
{
  catppuccin,
  fokquote,
  home-manager,
  lib,
  # nethack,
  nixvim,
  pkgs,
  sadan4,
  ...
}: {
  imports = [
    nixvim.homeManagerModules.nixvim
    catppuccin.homeManagerModules.catppuccin
  ];
  system.hashedPassword = "$y$j9T$lfDMkzctZ7jVUA.rK6U/3/$stLjTnRqME75oum.040Ya7tKAPsnIJ.gAZYQk57vNp2";
  system.userDescription = "PoolloverNathan";
  catppuccin = {
    enable = true;
    flavor = "frappe";
    accent = "sky";
  };
  home.stateVersion = "24.11";
  home.packages = builtins.attrValues rec {
    inherit (pkgs)
    blockbench
    clinfo
    ed
    fprintd
    ghc
    glxinfo
    jdk17
    # kde-connect
    prismlauncher
    python312Full
    vscodium
    xclip
    xsel;
    # nethack_ = nethack.packages.${pkgs.system}.default;
    # inherit (pkgs.jetbrains)
    # idea-community;
    discord = pkgs.discord.override {
      withOpenASAR = true;
      withVencord = true;
      inherit vencord;
    };
    vencord = (import "${sadan4}/customPackages" { inherit pkgs; }).vencord.overrideAttrs {
      # patches = [./vencord-no-required.patch];
      # patchFlags = ["-p0"];
    };
    fok-quote = fokquote.packages.${pkgs.system}.default;
  };
  # let powerline access catppuccin
  home.file.".config/powerline/colors.json".text = builtins.toJSON {
    colors = lib.mapAttrs (_: { hex, ... }: [27 (builtins.substring 1 6 hex)]) ctpPalette;
    gradients = {};
  };
  home.file.".config/powerline/colorschemes/catppuccin.json".text = builtins.toJSON {
    ext.bash.colorscheme = "catppuccin";
    groups = {
      cwd = {
        fg = "text";
        bg = "surface0";
      };
      "cwd:divider" = {
        fg = "subtext";
        bg = "surface0";
      };
      "cwd:current_folder" = {
        fg = "text";
        bg = "surface0";
        attrs = ["bold"];
      };
    };
  };
  # home.file.".config/powerline/themes/"
  programs = {
    bash = {
      enable = true;
      historyControl = ["ignoredups" "ignorespace"];
      historySize = -1;
    };
    emacs.enable = true;
    fastfetch.enable = true;
    firefox.enable = true;
    gh.enable = true;
    htop.enable = true;
    kitty.enable = true;
    nixvim = {
      enable = true;
      colorschemes.catppuccin.enable = true;
      plugins.lightline.enable = true;
    };
    ssh = {
      enable = true;
      matchBlocks = {
        bunny = {
          host = "nixos.kamori-ghoul.ts.net";
          port = 2222;
        };
      };
    };
    thefuck = {
      enable = true;
      enableBashIntegration = true;
    };
    tmux.enable = true;
  };
}
