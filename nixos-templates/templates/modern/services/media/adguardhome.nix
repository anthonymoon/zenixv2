{ config
, lib
, pkgs
, ...
}: {
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    settings = {
      schema_version = 14;
      users = [ ];
      http = {
        address = "0.0.0.0:3000";
      };
      dns = {
        bind_hosts = [ "0.0.0.0" ];
        port = 53;
        protection_enabled = true;
        filtering_enabled = true;
        parental_enabled = false;
        safebrowsing_enabled = false;
        safesearch_enabled = false;
        upstream_dns = [
          "https://dns.cloudflare.com/dns-query"
          "https://dns.google/dns-query"
          "tls://1.1.1.1"
          "tls://8.8.8.8"
        ];
        bootstrap_dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];
        fallback_dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];
        cache_size = 4194304;
        cache_ttl_min = 60;
        cache_ttl_max = 86400;
      };
      filtering = {
        rewrites = [ ];
      };
      dhcp = {
        enabled = false;
      };
      log = {
        enabled = true;
        file = "";
        max_backups = 0;
        max_size = 100;
        max_age = 3;
        compress = false;
        local_time = false;
        verbose = false;
      };
      os = {
        group = "";
        rlimit_nofile = 0;
        user = "";
      };
    };
  };
}
