{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # DNS tools
    bind
    dnsutils
    dig
    nslookup
    host

    # Network diagnostics
    ping
    traceroute
    mtr

    # Bandwidth monitoring
    iftop
    nethogs
    bwm-ng
    speedtest-cli
    iperf3

    # Packet analysis
    tcpdump
    wireshark-cli
    ngrep

    # Network scanning
    nmap
    masscan
    arp-scan

    # Firewall tools
    iptables
    nftables

    # VPN tools
    openvpn
    wireguard-tools

    # SSH and remote access
    openssh
    mosh

    # Network utilities
    socat
    netcat
    telnet
    ethtool
    bridge-utils

    # Monitoring
    arpwatch
    net-snmp

    # File transfer
    rsync
    lftp
    aria2

    # Network configuration
    iproute2
    networkmanager

    # DNS/DHCP servers
    dnsmasq
  ];
}
