
# from: https://n377.de/mikrotik-routeros-script-update-the-firewall-with-dynamic-ipv6-prefix.html
# and: https://forum.mikrotik.com/viewtopic.php?t=121114#p595465

:local comment "dynamic prefix";

:local PREFIX2IP6 do={
    :return [:toip6 [:pick $1 0 [:find $1 "/" 0]]];
};

:local EXTRACTQUOTE do={
    :local start [:find $1 "\"" 0];
    :local end [:find $1 "\"" $start];
    :if ($start>=0 && $end>$start) do={
        :return [:pick $1 ($start+1) $end];
    };
    :return "";
};

/ipv6 firewall address-list;
:foreach addrlist in=[find comment~"dynamic prefix"] do={
    :local addr [get number=$addrlist address];
    :local listname [get number=$addrlist list];
    :local ifname [$EXTRACTQUOTE [get number=$addrlist comment]];
    :if (0=[:len $ifname]) do={
        :log warning "dynamic_prefix_update: An address list entry is marked for update but does not name an interface.";
    } else={
        :local ifaddresses [/ipv6 address find global interface=$ifname from-pool=ipv6];
        :if (1!=[:len $ifaddresses]) do={
            :log warning "dynamic_prefix_update: Found $[:len $ifaddresses] global IPv6 addresses for interface \"$ifname\".";
        } else={
            :local addrlen [:pick $addr ([:find $addr "/" 0]+1) [:len $addr]];
            :local prefix [/ipv6 address get number=($ifaddresses->0) address];
            :local prefixlen [:pick $prefix ([:find $prefix "/" 0]+1) [:len $prefix]];
            :if ($addrlen < $prefixlen) do={
                :set prefixlen $addrlen;
            };
            :local mask [$PREFIX2IP6 [[:parse ":return $(~::)/$prefixlen"]]];
            :local newaddr ((([$PREFIX2IP6 $addr] & ~$mask) | ([$PREFIX2IP6 $prefix] & $mask))."/".$addrlen);
            :if ($addr!=$newaddr) do={
                :log info "dynamic_prefix_update: Updating \"$listname\" $addr -> $newaddr (prefix from \"$ifname\").";
                set number=$addrlist address=$newaddr;
            };
        };
    };
};