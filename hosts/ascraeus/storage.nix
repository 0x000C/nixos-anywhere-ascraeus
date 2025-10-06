{ ... }:
{
  disko.devices = {
    disk = {
      boot = {
        type = "disk";
        device = "/dev/sdc";
        content = {
          type = "gpt";
          partitions.EFI = {
            size = "1G";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "defaults" "noatime" ];
              label = "BOOT";
            };
          };
        };
      };
      primary = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions.cryptroot = {
            size = "100%";
            type = "8300";
            content = {
              type = "luks";
              name = "cryptroot";
              settings.allowDiscards = true;
              passwordFile = "/tmp/luks-passphrase";
              content = {
                type = "lvm_pv";
                vg = "vg0";
              };
            };
          };
        };
      };
    };

    lvm_vg.vg0 = {
      type = "lvm_vg";
      lvs = {
        root = {
          size = "100%FREE";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            label = "nixos-root";
            mountOptions = [ "noatime" "discard" ];
          };
        };
        swap = {
          size = "16G";
          content = {
            type = "swap";
            resumeDevice = true;
            label = "SWAP";
          };
        };
      };
    };
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/nixos-root";
      fsType = "ext4";
      options = [ "noatime" "discard" ];
    };
    "/boot" = {
      device = "/dev/disk/by-label/BOOT";
      fsType = "vfat";
      options = [ "noatime" ];
    };
  };

  swapDevices = [
    { device = "/dev/disk/by-label/SWAP"; }
  ];
}
