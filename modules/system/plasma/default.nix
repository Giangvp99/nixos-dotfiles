{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.systemSettings.plasma;
in
{
  options = {
    systemSettings.plasma = {
      enable = lib.mkEnableOption "Enable plasma";
    };
  };

  config = lib.mkIf cfg.enable {
    systemSettings.tlp.enable = lib.mkForce false;
    services.xserver.enable = true;
    services.xserver.xkb = {
      variant = "";
      options = "caps:escape";
      layout = "us";
    };
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    services.desktopManager.plasma6.enable = true;

    services.printing.enable = true;

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    environment.systemPackages = with pkgs; [
      kdePackages.kate
      kdePackages.dolphin
    ];

    virtualisation.waydroid.enable = true;
    services.avahi.nssmdns4 = true;
  };
}
