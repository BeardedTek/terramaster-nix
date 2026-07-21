{ config, pkgs, ... }:

let
  lanIf = config.mySystem.lanInterface;
in
{
  # Optional: available for any Linux/Nebula-connected client, though the
  # two stated clients (macOS + Android) are covered by Samba already.
  services.nfs.server.enable = true;

  # Disable NFSv3/v2 so only NFSv4 (a single TCP port, no rpcbind/mountd
  # sprawl) is served.
  services.nfs.settings.nfsd = {
    vers3 = false;
    vers2 = false;
  };

  # /etc/exports is normally an immutable symlink into the Nix store, built
  # once from a static string at build time — it can't adapt on its own to
  # "whatever network this box is currently plugged into". Disable that
  # management and generate /etc/exports ourselves right before nfs-server
  # starts: always allow the Nebula mesh (10.100.0.0/24, static — matches
  # secrets/extra-files/etc/nebula/config.yaml's tun subnet), plus whatever
  # IPv4 subnet is currently live on mySystem.lanInterface, detected fresh
  # on every service start/boot.
  #
  # Tradeoff worth knowing: if this box is ever plugged into an untrusted
  # network on that interface, NFS opens to that network's whole subnet
  # automatically, with no manual review step. Reasonable for a home LAN
  # that doesn't change; reconsider if that assumption changes.
  environment.etc."exports".enable = false;

  systemd.services.nfs-server.preStart = ''
    lan_cidr=$(${pkgs.iproute2}/bin/ip -4 -o route show dev "${lanIf}" scope link | ${pkgs.gawk}/bin/awk '{print $1}' | head -n1)
    clients="10.100.0.0/24(rw,sync,no_subtree_check,no_root_squash)"
    if [ -n "$lan_cidr" ]; then
      clients="$clients $lan_cidr(rw,sync,no_subtree_check,no_root_squash)"
    else
      echo "nfs-exports: no live IPv4 subnet detected on ${lanIf}, exporting to the Nebula mesh only" >&2
    fi
    cat > /etc/exports <<EOF
/rust/media $clients
/rust/data  $clients
EOF
    ${pkgs.nfs-utils}/bin/exportfs -ra
  '';

  networking.firewall.interfaces.${lanIf}.allowedTCPPorts = [ 2049 ];
  networking.firewall.interfaces."nebula1".allowedTCPPorts = [ 2049 ];
}
