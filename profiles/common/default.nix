_:

{
  systemSettings = {
    secrets.enable = true;
    scripts.enable = true;

    security = {
      automount.enable = true;
      firewall.enable = true;
      gpg.enable = true;
      base.enable = true;
    };

    backup = {
      enable = true;
      packagesOnly = true;
    };
  };
}
