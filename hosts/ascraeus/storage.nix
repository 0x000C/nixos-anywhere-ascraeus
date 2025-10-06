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
            label = "BOOT";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [ "defaults" "noatime" ];
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
            label = "cryptroot";
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
            mountOptions = [ "noatime" "discard" ];
          };
        };
        swap = {
          size = "16G";
          content = {
            type = "swap";
            resumeDevice = true;
          };
        };
      };
    };
  };
}
