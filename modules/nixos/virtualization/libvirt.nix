{ config
, lib
, pkgs
, ...
}:

let
  cfg = config.my.virtualization.libvirt;
in
{
  options.my.virtualization.libvirt = {
    enable = lib.mkEnableOption "libvirt/QEMU virtualization";

    users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Users added to the libvirtd group.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      libvirtd = {
        enable = true;

        qemu = {
          package = pkgs.qemu_kvm;

          swtpm = {
            enable = true;
          };
        };
      };

      spiceUSBRedirection.enable = true;
    };

    users.users = lib.genAttrs cfg.users (_: {
      extraGroups = [ "libvirtd" ];
    });

    programs.virt-manager.enable = true;

    environment.systemPackages = with pkgs; [
      spice
      spice-gtk
      spice-protocol
      virt-viewer
    ];
  };
}
