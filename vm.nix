{
  config,
  lib,
  pkgs,
  ...
}:
let
  ignoredHDDs = [
    "9.00"
    "10.00"
  ];
  qemu-anti-detection = (pkgs.qemu.override { hostCpuOnly = true; }).overrideAttrs (
    finalAttrs: previousAttrs: {
      # ref: https://github.com/zhaodice/qemu-anti-detection
      patches = (previousAttrs.patches or [ ]) ++ [
        (pkgs.fetchpatch {
          url = "https://raw.githubusercontent.com/zhaodice/qemu-anti-detection/main/qemu-8.1.0.patch";
          sha256 = "sha256-N+3YRvOwIu+k1d0IYxwV6zWmfJT9jle38ywOWTbgX8Y=";
        })
      ];
      version = "8.1.2";
    }
  );
  clibvirt = pkgs.libvirt.override { qemu = qemu-anti-detection; };
in
{
  imports = [ ./gpu-bypass.nix ];
  virtualisation = {
    spiceUSBRedirection.enable = true;
    libvirtd = {
      enable = true;
      onBoot = "ignore";
      onShutdown = "shutdown";
      package = clibvirt;
    };
  };
  # environment.systemPackages = [
  #   clibvirt
  # ];

  # services.libvirtd.package = clibvirt;

  # pkgs.libvirt.override = { qemu = qemu-anti-detection };

  boot = {
    # kernelParams = lib.mkAfter [
    #   "libata.force=${lib.concatStringsSep "," (map (port: "${port}:disable") ignoredHDDs)}"
    # ];
    initrd.kernelModules = lib.mkBefore [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
    ];
  };

  programs.virt-manager.enable = true;

  environment.systemPackages = with pkgs; [
    looking-glass-client
    spice-vdagent
  ];

  systemd.tmpfiles.rules = [ "f /dev/shm/looking-glass 0660 red qemu-libvertd -" ];

}
