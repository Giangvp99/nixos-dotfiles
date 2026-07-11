{ config
, lib
, ...
}:

let
  cfg = config.systemSettings.browser.bravePolicy;
in
{
  options.systemSettings.browser.bravePolicy = {
    enable = lib.mkEnableOption "Enable Brave browser policy";
  };

  config = lib.mkIf cfg.enable {
    environment.etc."brave/policies/managed/policies.json".text = builtins.toJSON {
      BraveRewardsDisabled = true;
      BraveWalletDisabled = true;
      TorDisabled = false;

      PasswordManagerEnabled = false;
      AutofillAddressEnabled = false;
      AutofillCreditCardEnabled = false;

      DefaultBrowserSettingEnabled = false;
      MetricsReportingEnabled = false;

      SafeBrowsingProtectionLevel = 1;

      DNSInterceptionChecksEnabled = true;

      ExtensionInstallBlocklist = [
        "*"
      ];

      ExtensionInstallAllowlist = [
        # Thêm ID extension bạn thật sự cần ở đây.
      ];
    };
  };
}
