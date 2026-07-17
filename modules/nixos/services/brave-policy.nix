{ config
, lib
, ...
}:

let
  cfg = config.my.services.bravePolicy;
in
{
  options.my.services.bravePolicy.enable =
    lib.mkEnableOption "managed Brave browser policies";

  config = lib.mkIf cfg.enable {
    environment.etc."brave/policies/managed/policies.json".text =
      builtins.toJSON {
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

        ExtensionInstallAllowlist = [ ];
      };
  };
}
