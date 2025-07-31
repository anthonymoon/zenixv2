{ config
, lib
, pkgs
, ...
}: {
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "br0" "virbr0" "docker0" ];
    allowedTCPPorts = [
      22 # SSH
      80 # HTTP
      443 # HTTPS
      445 # Samba
      139 # Samba
      5357 # WSDD
      3000 # AdGuard Home
      9117 # Jackett
      5000 # Nix serve
      9090 # Cockpit
      1965 # Gemini
      6443 # k3s
      8080 # Web services
      19999 # Netdata
    ];
    allowedUDPPorts = [
      53 # DNS
      137 # NetBIOS
      138 # NetBIOS
      3702 # WSDD
      5353 # mDNS
      5355 # LLMNR
    ];
    allowedTCPPortRanges = [
      {
        from = 1714;
        to = 1764;
      } # KDE Connect
    ];
    allowedUDPPortRanges = [
      {
        from = 1714;
        to = 1764;
      } # KDE Connect
    ];
    extraCommands = ''
      # Allow ICMP
      iptables -A INPUT -p icmp -j ACCEPT
      # Allow established connections
      iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
      # Allow local traffic
      iptables -A INPUT -i lo -j ACCEPT
      # Allow bridge traffic
      iptables -A FORWARD -m physdev --physdev-is-bridged -j ACCEPT
    '';
  };
}
