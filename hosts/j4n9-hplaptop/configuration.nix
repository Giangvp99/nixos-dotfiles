{
  pkgs,
  ...
}:

{
  config = {
    systemSettings = {
      users = [ "ntgiang" ];
      adminUsers = [ "ntgiang" ];

      dotfilesDir = "/etc/nixos";
      bluetooth.enable = true;
      printing.enable = true;
      tlp.enable = true;

      stylix = {
        enable = true;
        theme = "dracula";
      };
      security = {
        automount.enable = true;
        firewall.enable = true;
        gpg.enable = true;
        sshd.enable = false;
      };

      virtualization = {
        docker.enable = true;
      };

      hyprland.enable = false;
      plasma.enable = true;
    };

    users.users.ntgiang.description = "Nguyen Truong Giang";
    # home-manager.users.ntgiang.userSettings = {
    #   name = "Nguyen Truong Giang";
    # };
  };
}
