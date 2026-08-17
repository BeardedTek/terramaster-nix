# Appends a NAS-SECRETS FAT32 partition after the existing installer ISO's
# own bytes, producing one combined image that's flashable exactly like a
# plain ISO (dd/Rufus/balenaEtcher — no new tooling on the flashing
# machine, no WSL, no second USB drive) while also carrying a
# blkid -L NAS-SECRETS-labeled partition that
# hosts/installer/wizard/stages/70-secrets.sh already auto-detects with no
# changes needed on that side.
#
# Because this only appends bytes after the ISO9660 filesystem's own
# declared extent, the result is still a fully valid ISO9660 image too —
# any ISO-aware reader (mount -o loop, IPMI/BMC virtual media, a VM's
# "attach ISO") honors the volume descriptor's size field and ignores the
# trailing partition data. Only writing the file to a raw block device
# exposes the second partition.
#
# Built entirely with unprivileged tooling — no loop devices, no mount, no
# root, safe inside a normal sandboxed Nix build:
#   - sfdisk operates directly on the plain output file (confirmed
#     working, including --append, against a real release ISO with no
#     loop device).
#   - mkfs.fat --offset formats just the new partition's byte range in
#     place ("Write the filesystem at a specific sector into the device
#     file" — exists specifically so you don't need a loop device).
#   - mtools' mcopy -i img@@byteoffset populates that range directly, the
#     same trick nixpkgs' own ISO builder already uses internally to
#     populate its embedded EFI System Partition.
#
# secretsDir, if given, may contain *.example template files alongside (or
# instead of) real ones (see secrets/nas-secrets-usb/) — those are always
# excluded from what actually lands on the partition, so the directory's
# mere existence (true once the checked-in .example files are present)
# never causes placeholder content to ship on a real image.
{ pkgs, isoImage, secretsDir ? null, secretsPartitionMiB ? 64 }:

let
  inherit (pkgs) lib;
in
pkgs.runCommand "beardednas-installer.iso"
{
  nativeBuildInputs = with pkgs; [ util-linux dosfstools mtools jq ];
} ''
  iso=(${isoImage}/iso/*.iso)
  cp "''${iso[0]}" $out
  chmod +w $out

  isoSize=$(stat -c%s $out)
  partBytes=$((${toString secretsPartitionMiB} * 1024 * 1024))
  # +2MiB slack beyond the requested partition size: sfdisk aligns
  # partition starts to a 1MiB boundary, so an exact-fit truncation
  # leaves no room for that alignment rounding and --append fails with
  # "No space left on device" even though the nominal size is free
  # (confirmed the hard way against a real ISO before writing this).
  truncate -s "$((isoSize + partBytes + 2 * 1024 * 1024))" $out

  echo ",${toString secretsPartitionMiB}MiB,c" | sfdisk --append $out

  # sfdisk -d's plain-text output field-pads its values ("start=     123,"
  # — the number is a SEPARATE whitespace-split token from "start="),
  # which breaks naive awk parsing. JSON + jq sidesteps that entirely.
  read -r startSector sizeSectors < <(
    sfdisk -J $out | jq -r '.partitiontable.partitions[] | select(.type=="c") | "\(.start) \(.size)"'
  )
  byteOffset=$((startSector * 512))
  size1kBlocks=$((sizeSectors / 2))

  mkfs.fat -F 32 -n NAS-SECRETS --offset "$startSector" $out "$size1kBlocks"

  ${lib.optionalString (secretsDir != null) ''
    # Stage only the real (non-.example) files, preserving their relative
    # layout, so a fresh checkout with nothing but the checked-in
    # .example templates ends up copying nothing at all.
    secretsReal=$(mktemp -d)
    (cd ${secretsDir} && find . -type f ! -name '*.example' -exec cp --parents -t "$secretsReal" {} +)
    shopt -s nullglob dotglob
    entries=("$secretsReal"/*)
    if [ ''${#entries[@]} -gt 0 ]; then
      mcopy -i "$out@@$byteOffset" -s "''${entries[@]}" ::
    fi
  ''}
''
