{
  imports = [
    ../../modules/nixos/core/boot.nix
    ../../modules/nixos/core/journald.nix
    ../../modules/nixos/core/locale.nix
    ../../modules/nixos/core/networking.nix
    ../../modules/nixos/core/nix.nix
    ../../modules/nixos/core/packages.nix

    ../../modules/nixos/hardware/kernel.nix

    ../../modules/nixos/security/firewall.nix
    ../../modules/nixos/security/hardening.nix
    ../../modules/nixos/security/secrets.nix

    ../../modules/nixos/services/backup.nix
    ../../modules/nixos/services/maintenance.nix
    ../../modules/nixos/services/scripts.nix
    ../../modules/nixos/services/protonvpn.nix
    #    ../../modules/nixos/virtualization/vmware.nix
    ../../modules/nixos/virtualization/libvirt.nix
  ];

  my = {
    core = {
      boot.enable = true;
      journald.enable = true;
      locale.enable = true;
      networking.enable = true;
      nix = {
        enable = true;
        trustedUsers = [
          "root"
          "ntgiang"
        ];
      };
      packages.enable = true;
    };

    hardware.kernel = {
      enable = true;
      package = "stable";
    };

    security = {
      firewall = {
        enable = true;
        allowSyncthing = false;
      };

      hardening = {
        enable = true;
        firejailFirefox = false;
      };

      secrets.enable = true;
    };

    services = {
      backup = {
        enable = true;
        packagesOnly = true;
      };

      maintenance = {
        enable = true;
        flakeDirectory = "/etc/nixos";
        autoUpdateCheck = true;
        updateCheckCalendar = "Sun 10:00";
      };

      protonvpn.enable = true;

      scripts = {
        enable = true;
        flakeDirectory = "/etc/nixos";
      };
    };
    # virtualization.vmware.enable = true;
    virtualization.libvirt = {
      enable = true;
      users = [ "ntgiang" ];
    };
  };
}
