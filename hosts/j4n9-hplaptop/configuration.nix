_:

{
  config = {
    systemSettings = {
      users = [ "ntgiang" ];
      adminUsers = [ "ntgiang" ];

      dotfilesDir = "/etc/nixos";
      kernel = {
        enable = true;
        package = "stable";
        intelCpu = true;
        amdCpu = false;
      };
      secrets.enable = true;
      bluetooth.enable = true;
      printing.enable = true;
      tlp.enable = true;
      flatpak.enable = true;

      stylix = {
        enable = true;
        theme = "dracula";
      };
      security = {
        automount.enable = true;
        firewall = {
          enable = true;
          allowSyncthing = false;
        };
        gpg.enable = true;
        sshd.enable = false;
        # sshd = {
        #   enable = true;
        #   authorizedKeys = [
        #     "ssh-ed25519 AAAA... your-key"
        #   ];
        # };
        base.enable = true;
      };

      backup = {
        enable = true;
        packagesOnly = true;
      };

      maintenance = {
        enable = true;
        autoUpdateCheck = false;
      };

      virtualization = {
        docker = {
          enable = true;
          addUsersToDockerGroup = false;
        };
      };

      hyprland.enable = false;
      plasma.enable = true;
      scripts.enable = true;
      browser.bravePolicy.enable = true;
    };

    users.users.ntgiang.description = "Nguyen Truong Giang";
    # home-manager.users.ntgiang.userSettings = {
    #   name = "Nguyen Truong Giang";
    # };
  };
}
