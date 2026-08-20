{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.desktop.hyprland;
in
{
  config = lib.mkIf cfg.enable {
    programs.waybar = {
      enable = true;

      systemd = {
        enable = true;
        targets = [ "graphical-session.target" ];
      };

      settings.mainBar = {
        layer = "top";
        position = "top";

        height = 34;
        spacing = 6;

        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];

        modules-center = [
          "clock"
        ];

        modules-right = [
          "tray"
          "idle_inhibitor"
          "pulseaudio"
          "backlight"
          "network"
          "bluetooth"
          "battery"
        ];

        "hyprland/workspaces" = {
          disable-scroll = true;
          all-outputs = false;
          format = "{name}";

          persistent-workspaces = {
            "*" = 5;
          };
        };

        "hyprland/window" = {
          max-length = 60;
          separate-outputs = true;
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%A, %d/%m/%Y}";
          tooltip-format = "<tt>{calendar}</tt>";
        };

        tray = {
          spacing = 10;
        };

        idle_inhibitor = {
          format = "{icon}";

          format-icons = {
            activated = "";
            deactivated = "";
          };
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟";

          format-icons = {
            default = [
              ""
              ""
              ""
            ];
          };

          on-click = "${lib.getExe pkgs.pavucontrol}";
        };

        backlight = {
          format = "󰃟 {percent}%";
        };

        network = {
          format-wifi = "  {signalStrength}%";
          format-ethernet = "󰈀";
          format-disconnected = "󰖪";
          tooltip-format = "{ifname}: {ipaddr}";
          on-click = "${pkgs.networkmanagerapplet}/bin/nm-connection-editor";
        };

        bluetooth = {
          format = "";
          format-disabled = "󰂲";
          format-connected = " {num_connections}";
        };

        battery = {
          states = {
            warning = 25;
            critical = 10;
          };

          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";

          format-icons = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
        };
      };

      style = builtins.readFile ./config/waybar.css;
    };
  };
}
