{ config
, lib
, pkgs
, ...
}: {
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    recommendedBrotliSettings = true;
    eventsConfig = ''
      worker_connections 4096;
      use epoll;
      multi_accept on;
    '';
    appendConfig = ''
      worker_processes auto;
      worker_rlimit_nofile 100000;
      pcre_jit on;
      sendfile on;
      tcp_nopush on;
      tcp_nodelay on;
      keepalive_timeout 65;
      types_hash_max_size 2048;
      server_tokens off;
      more_clear_headers Server;
      client_max_body_size 100M;
      open_file_cache max=200000 inactive=20s;
      open_file_cache_valid 30s;
      open_file_cache_min_uses 2;
      open_file_cache_errors on;
    '';
    virtualHosts = {
      "_" = {
        default = true;
        root = "/var/www/default";
        extraConfig = ''
          return 444;
        '';
      };
      "home.lan" = {
        root = "/var/www/home";
        extraConfig = ''
          autoindex on;
          autoindex_exact_size off;
          autoindex_localtime on;
        '';
      };
    };
  };
}
