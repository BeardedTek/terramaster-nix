{ config, pkgs, ... }:

let
  lanIf = config.mySystem.lanInterface;
in
{
  services.nfs.server.enable = true;
  services.nfs.settings.nfsd = {
    vers3 = false;
    vers2 = false;
  };
  environment.etc."exports".enable = false;
  systemd.services.nfs-server.unitConfig.RequiresMountsFor = [ "/rust/media" "/rust/data" ];

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
