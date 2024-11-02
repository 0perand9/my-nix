{ pkgs, lib, config, ... }:
let
  # RTX 3070 Ti
  gpuIDs = [
    "10de:2484" # Graphics
    "10de:228b" # Audio
  ];
in {
  boot = {
    kernelParams = lib.mkBefore [
      "amd_iommu=on"
      "vfio-pci.ids=${lib.concatStringsSep "," gpuIDs}"
    ];
  };
}
