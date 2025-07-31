{ config
, lib
, pkgs
, ...
}: {
  environment.systemPackages = with pkgs; [
    # Container runtime
    docker
    docker-compose
    podman
    podman-compose
    buildah
    skopeo

    # Container management
    lazydocker

    # Virtualization
    qemu
    qemu-utils
    libvirt
    virt-manager
    virt-viewer

    # Kubernetes tools
    kubectl
    kubernetes-helm
    minikube
    k9s

    # Other virtualization
    virtualbox
    vagrant

    # Container registry
    docker-registry

    # Image building
    packer
  ];

  # Enable virtualization
  virtualisation = {
    docker.enable = true;
    podman.enable = true;
    libvirtd.enable = true;
  };
}
