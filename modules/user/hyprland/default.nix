{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.userSettings.hyprland;
  font = config.stylix.fonts.monospace.name;
  term = config.userSettings.terminal;
  # spawnEditor = config.userSettings.spawnEditor;
  # spawnBrowser = config.userSettings.spawnBrowser;
  performance = config.userSettings.hyprland.performanceOptimizations;
in
{
  options = {
    userSettings.hyprland = {
      enable = lib.mkEnableOption "Enable hyprland";
      performanceOptimizations = lib.mkOption {
        default = false;
        type = lib.types.bool;
        description = "Enable performance optimizations";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    userSettings.alacritty.enable = true;
    programs.alacritty.settings.window.opacity = lib.mkOverride 40 (if performance then 1.0 else 0.80);
    userSettings.kitty.enable = true;
    programs.kitty.settings.background_opacity = lib.mkOverride 40 (
      if performance then "1.0" else "0.80"
    );
    # userSettings.emacs.opacity = lib.mkOverride 40 (if performance then 100 else 80);
    userSettings.dmenuScripts = {
      enable = true;
      dmenuCmd = "fuzzel -d";
    };
    # userSettings.hyprland.hyprprofiles.enable = lib.mkDefault true;
    userSettings.stylix.enable = true;

    home.sessionVariables = {
      NIXOS_OZONE_WL = 1;
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      GDK_BACKEND = "wayland,x11,*";
      QT_QPA_PLATFORM = "wayland;xcb";
      #QT_QPA_PLATFORMTHEME = lib.mkForce "qt5ct";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1.25";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
      CLUTTER_BACKEND = "wayland";
      #GDK_PIXBUF_MODULE_FILE = "${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
      #GSK_RENDERER = "gl";
      XCURSOR_THEME = config.gtk.cursorTheme.name;
      GDK_DEBUG = "portals";
      GTK_USE_PORTALS = 1;
      GRIM_DEFAULT_DIR = config.xdg.userDirs.extraConfig.XDG_SCREENSHOT_DIR;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-termfilechooser
      ];
    };

    xdg.portal.config.common = {
      default = [ "hyprland" ];
      "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
    };
    xdg.portal.config.hyprland = {
      default = [ "hyprland" ];
      "org.freedesktop.impl.portal.FileChooser" = "termfilechooser";
    };

    home.sessionVariables.TERMCMD = "kitty --class=filechoose_yazi";

    xdg.configFile."xdg-desktop-portal-termfilechooser/config" = {
      force = true;
      text = ''
        [filechooser]
        cmd=${pkgs.xdg-desktop-portal-termfilechooser}/share/xdg-desktop-portal-termfilechooser/yazi-wrapper.sh
      '';
    };

    gtk.cursorTheme = {
      package = pkgs.quintom-cursor-theme;
      name = if (config.stylix.polarity == "light") then "Quintom_Ink" else "Quintom_Snow";
      size = 36;
    };

    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      plugins = [ ];
      systemd.variables = [ "--all" ];
      xwayland = {
        enable = true;
      };
      systemd.enable = true;
    };
    xdg.configFile."hypr/hyprland.lua".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/dotfiles/hypr/hyprland.lua";
    home.packages = (
      with pkgs;
      [
        qpwgraph
        networkmanagerapplet
        hyprland-monitor-attached
        alacritty
        kitty
        killall
        polkit_gnome
        nwg-launchers
        (lib.hiPrio papirus-icon-theme)
        (pkgs.writeScriptBin "nwggrid-wrapper" ''
          #!/bin/sh
          if pgrep -x "nwggrid-server" > /dev/null
          then
            nwggrid -client
          else
            GDK_PIXBUF_MODULE_FILE=${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache nwggrid-server -layer-shell-exclusive-zone -1 -g adw-gtk3 -o 0.55 -b ${config.lib.stylix.colors.base00} &
            sleep 0.6 && nwggrid -client
          fi
        '')
        libva-utils
        libinput-gestures
        gsettings-desktop-schemas
        hyprnome
        wlr-randr
        wtype
        ydotool
        wl-clipboard
        hyprland-protocols
        hyprpicker
        inputs.hyprlock.packages.${pkgs.system}.default
        hypridle
        hyprpaper
        fnott
        keepmenu
        pinentry-gnome3
        wev
        grim
        slurp
        kdePackages.qtwayland
        xdg-utils
        wlsunset
        hyprshade
        pavucontrol
        (pkgs.writeScriptBin "workspace-on-monitor" ''
          #!/bin/sh
          hyprctl monitors -j | jq ".[$1] | .activeWorkspace.id"
        '')
        (pkgs.writeScriptBin "sct" ''
          #!/bin/sh
          killall wlsunset &> /dev/null;
          if [ $# -eq 1 ]; then
            temphigh=$(( $1 + 1 ))
            templow=$1
            wlsunset -t $templow -T $temphigh &> /dev/null &
          else
            killall wlsunset &> /dev/null;
          fi
        '')
        (pkgs.writeScriptBin "scg" ''
          #!/bin/sh
          hyprshade toggle grayscale;
        '')
        (pkgs.writeScriptBin "obs-notification-mute-daemon" ''
          #!/bin/sh
          while true; do
            if pgrep -x .obs-wrapped > /dev/null;
              then
                pkill -STOP fnott;
              else
                pkill -CONT fnott;
            fi
            sleep 10;
          done
        '')
        (pkgs.writeScriptBin "suspend-unless-render" ''
          #!/bin/sh
          if pgrep -x nixos-rebuild > /dev/null || pgrep -x home-manager > /dev/null || pgrep -x kdenlive > /dev/null || pgrep -x FL64.exe > /dev/null || pgrep -x blender > /dev/null || pgrep -x flatpak > /dev/null;
          then echo "Shouldn't suspend"; sleep 10; else echo "Should suspend"; systemctl suspend; fi
        '')
      ]
    );
    services.hyprpolkitagent.enable = true;
    services.swayosd.enable = true;
    services.swayosd.topMargin = 0.5;
    services.udiskie.enable = true;
    services.udiskie.tray = "never";
    programs.fuzzel.enable = true;
    programs.fuzzel.package = pkgs.fuzzel;
    programs.fuzzel.settings = {
      main = {
        font = font + ":size=20";
        dpi-aware = "no";
        show-actions = "yes";
        terminal = "${pkgs.alacritty}/bin/alacritty";
      };
      colors = {
        background = config.lib.stylix.colors.base00 + (if performance then "ff" else "bf");
        text = config.lib.stylix.colors.base07 + "ff";
        match = config.lib.stylix.colors.base05 + "ff";
        selection = config.lib.stylix.colors.base08 + "ff";
        selection-text = config.lib.stylix.colors.base00 + "ff";
        selection-match = config.lib.stylix.colors.base05 + "ff";
        border = config.lib.stylix.colors.base08 + "ff";
      };
      border = {
        width = 0;
        radius = 0;
      };
    };
    services.fnott.enable = true;
    services.fnott.settings = {
      main = {
        anchor = "bottom-right";
        stacking-order = "top-down";
        min-width = 520;
        title-font = font + ":size=18";
        summary-font = font + ":size=15";
        body-font = font + ":size=14";
        border-size = 0;
      };
      low = {
        background = config.lib.stylix.colors.base00 + "e6";
        title-color = config.lib.stylix.colors.base03 + "ff";
        summary-color = config.lib.stylix.colors.base03 + "ff";
        body-color = config.lib.stylix.colors.base03 + "ff";
        idle-timeout = 150;
        max-timeout = 4;
        default-timeout = 2;
      };
      normal = {
        background = config.lib.stylix.colors.base00 + "e6";
        title-color = config.lib.stylix.colors.base07 + "ff";
        summary-color = config.lib.stylix.colors.base07 + "ff";
        body-color = config.lib.stylix.colors.base07 + "ff";
        idle-timeout = 150;
        max-timeout = 5;
        default-timeout = 3;
      };
      critical = {
        background = config.lib.stylix.colors.base00 + "e6";
        title-color = config.lib.stylix.colors.base08 + "ff";
        summary-color = config.lib.stylix.colors.base08 + "ff";
        body-color = config.lib.stylix.colors.base08 + "ff";
        idle-timeout = 0;
        max-timeout = 0;
        default-timeout = 0;
      };
    };
  };
}
