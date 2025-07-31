{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # Encryption
    gnupg
    openssl
    libressl

    # Password management
    pass
    pwgen
    keepassxc
    bitwarden-cli

    # SSH
    openssh
    ssh-audit
    sshpass

    # Network security
    nmap
    wireshark
    tshark

    # Vulnerability scanning
    nikto
    lynis

    # Firewall
    iptables
    nftables
    fail2ban

    # Secrets management
    sops
    age

    # Authentication
    pam_u2f
    yubikey-manager

    # Hashing
    hashcat
    john

    # Certificate management
    certbot
    mkcert

    # Security auditing
    aide
    rkhunter
    chkrootkit

    # Key management
    pinentry
    pinentry-curses
  ];
}
