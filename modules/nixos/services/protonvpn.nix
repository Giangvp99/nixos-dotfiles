{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.services.protonvpn;
in
{
  options.my.services.protonvpn = {
    enable = lib.mkEnableOption "Proton VPN";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      proton-vpn
      wireguard-tools
    ];

    # Required when routing all traffic through Proton VPN
    networking.firewall.checkReversePath = false;
  };
}
