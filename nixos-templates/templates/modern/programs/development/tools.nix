{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # Infrastructure as Code
    ansible
    terraform

    # Cloud tools
    awscli2
    google-cloud-sdk
    azure-cli

    # API tools
    httpie
    curl
    postman

    # Database clients
    postgresql
    mysql
    sqlite
    redis

    # Container tools
    dive # Docker image explorer
    hadolint # Dockerfile linter

    # CI/CD tools
    jenkins
    gitlab-runner

    # Code quality
    shellcheck
    yamllint
    jsonlint
  ];
}
