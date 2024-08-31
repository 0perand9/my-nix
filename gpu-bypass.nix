{ pkgs, lib, config, ... }: 
let
  # RTX 3070 Ti
  gpuIDs = [
    "10de:2484" # Graphics
    "10de:228b" # Audio
  ];
  qemu-anti-detection =
    (pkgs.qemu.override{
      hostCpuOnly = true;
    }).overrideAttrs (finalAttrs:
      previousAttrs: {
        # ref: https://github.com/zhaodice/qemu-anti-detection
        patches = (previousAttrs.patches or [ ]) ++ [
          (pkgs.fetchpatch {
            url =
              "https://raw.githubusercontent.com/zhaodice/qemu-anti-detection/main/qemu-8.1.0.patch";
            sha256 = "sha256-N+3YRvOwIu+k1d0IYxwV6zWmfJT9jle38ywOWTbgX8Y=";
          })
        ];
        postFixup =  (previousAttrs.postFixup or "") +  "\n" + ''
          for i in $(find $out/bin -type f -executable); do
            mv $i "$i-anti-detection"
          done
        '';
        version = "8.1.2";
        pname = "qemu-anti-detection";
      });
    clibvirt = pkgs.libvirt.override {
      qemu = qemu-anti-detection;
    };
in {
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
    initrd.kernelModules = [
      "vfio_pci"
      "vfio"
      "vfio_iommu_type1"
      
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];

    kernelPatches = [
      {
        name = "rdtsc";
        patch = ./patches/kernel/kernel.patch;
      }
    ];
    kernelParams = [
      # enable IOMMU
      "amd_iommu=on"
    ] ++ # isolate the GPU
      [ ("vfio-pci.ids=" + lib.concatStringsSep "," gpuIDs) ];
  };
}