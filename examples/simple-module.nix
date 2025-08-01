# Example of a simple module without over-abstraction
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Instead of complex option types and builders, just use simple options
  options.services.myapp = {
    enable = lib.mkEnableOption "my application";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port to listen on";
    };

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/myapp";
      description = "Data directory";
    };
  };

  config = lib.mkIf config.services.myapp.enable {
    # Direct systemd service configuration
    systemd.services.myapp = {
      description = "My Application";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        ExecStart = "${pkgs.myapp}/bin/myapp --port ${toString config.services.myapp.port}";
        StateDirectory = "myapp";
        DynamicUser = true;
        # Direct security hardening - no abstraction needed
        PrivateTmp = true;
        ProtectSystem = "strict";
        ProtectHome = true;
        NoNewPrivileges = true;
      };
    };

    # Direct firewall configuration
    networking.firewall.allowedTCPPorts = [config.services.myapp.port];
  };
}
