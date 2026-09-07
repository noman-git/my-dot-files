# Optional boot entries

These two entries are specific to this laptop's disk layout and are not
installed by `install_system.sh`. Copy them to `/boot/loader/entries/` by
hand if they apply.

- `efishellx64.conf`: boots the UEFI shell from `/boot/efishellx64.efi`
  (package `edk2-shell`, copy `/usr/share/edk2-shell/x64/Shell.efi` there).
- `windows11.conf`: chainloads Windows through the UEFI shell because the
  Windows ESP is a different partition. `HD0b:` is the shell's name for that
  partition on this machine; check it with `map` inside the shell.
