:local wgInterface "wireguard-eandi"
:local remoteHost "192.168.6.1"
:local initialPort 13232

:log warning "$wgInterface interface down"
:while ([/tool netwatch get [find host=$remoteHost] status] = "down") do={
  :local NEWPORT $initialPort
  :local CURRENT [/interface/wireguard get $wgInterface listen-port]

  :if ($NEWPORT=$CURRENT) do={
    :set NEWPORT ($NEWPORT + 1)
  }

  /interface/wireguard set $wgInterface listen-port=$NEWPORT
  :delay 120

  :if ([/tool netwatch get [find host=$remoteHost] status] = "down") do={  
    /interface wireguard peers disable [find interface=$wgInterface]
    :delay 60
    /interface wireguard peers enable [find interface=$wgInterface]
    :delay 240
  }
}
:log warning "$wgInterface interface restarted"