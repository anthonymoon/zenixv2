{ config
, lib
, pkgs
, ...
}: {
  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      X11Forwarding = true;
      GatewayPorts = "yes";
    };
    banner = "
╭─────────────────────────────────╮
│  S Y S T E M   A C C E S S      │
│  Authorized Users Only          │
│  All activity is monitored      │
╰─────────────────────────────────╯
";
  };
}
