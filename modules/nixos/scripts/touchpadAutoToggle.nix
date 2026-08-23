{ config
, lib
, pkgs
, ...
}:
let
  touchpadAutoToggle = pkgs.writeShellScriptBin "touchpad-auto-toggle" ''
    set -u

    TOUCHPAD="syna30f5:00-06cb:cebb-touchpad"
    MOUSE="/dev/input/by-id/usb-COMPANY_USB_Device-if01-event-mouse"

    HYPRCTL="${pkgs.hyprland}/bin/hyprctl"
    UDEVADM="${pkgs.systemd}/bin/udevadm"

    log() {
      echo "[touchpad-auto-toggle] $*"
    }

    set_touchpad() {
      local enabled="$1"

      if [[ "$enabled" == "true" ]]; then
        log "Enabling touchpad"

        "$HYPRCTL" eval \
          "hl.device({ name = \"$TOUCHPAD\", enabled = true })"
      else
        log "Disabling touchpad"

        "$HYPRCTL" eval \
          "hl.device({ name = \"$TOUCHPAD\", enabled = false })"
      fi
    }

    mouse_connected() {
      [[ -e "$MOUSE" ]]
    }

    update_touchpad() {
      if mouse_connected; then
        log "External mouse detected -> disabling touchpad"
        set_touchpad false
      else
        log "External mouse not detected -> enabling touchpad"
        set_touchpad true
      fi
    }

    log "Starting"

    # Wait until Hyprland is ready.
    sleep 1

    # Handle mouse already connected before login.
    update_touchpad

    log "Monitoring input devices..."

    "$UDEVADM" monitor \
      --udev \
      --subsystem-match=input \
      --property |
    while IFS= read -r line; do

      if [[ "$line" == "ACTION=add" ||
            "$line" == "ACTION=remove" ]]; then

        # Allow udev to finish creating/removing the device.
        sleep 0.2

        update_touchpad
      fi

    done
  '';
  cfg = config.my.scripts.touchpadAutoToggle;
in
{
  options.my.scripts.touchpadAutoToggle.enable = lib.mkEnableOption "Touchpad auto toggle support";

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      touchpadAutoToggle
    ];

    systemd.user.services.touchpad-auto-toggle = {
      description = "Automatically disable touchpad when external mouse is connected";

      wantedBy = [
        "graphical-session.target"
      ];

      after = [
        "graphical-session.target"
      ];

      serviceConfig = {
        ExecStart = "${touchpadAutoToggle}/bin/touchpad-auto-toggle";
        Restart = "always";
        RestartSec = 2;
        KillMode = "process";
      };
    };
  };
}
