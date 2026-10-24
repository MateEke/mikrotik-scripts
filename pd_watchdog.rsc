# RouterOS 7.25 workaround (SUP-226776), remove once fixed:
# re-apply from-pool ipv6 addresses that stopped working after a PD renewal

:local dhcpInterface "pppoe-out1"
:local ipv6Pool "ipv6"

:local dhcp [/ipv6 dhcp-client find interface=$dhcpInterface]
:if ([/ipv6 dhcp-client get $dhcp status] = "bound") do={
  :foreach id in=[/ipv6 address find from-pool=$ipv6Pool disabled=no] do={
    :local a [/ipv6 address get $id address]
    :if ([:pick $a 0 2] != "::") do={
      :local ip [:toip6 [:pick $a 0 [:find $a "/"]]]
      :if ([/ping address=$ip count=2] = 0) do={
        :log warning "pd-watchdog: $ip not usable, re-applying"
        /ipv6 address disable $id
        :delay 2s
        /ipv6 address enable $id
        :delay 5s
        :if ([/ping address=$ip count=2] = 0) do={
          :log error "pd-watchdog: $ip still not usable"
        } else={
          :log info "pd-watchdog: $ip restored"
        }
      }
    }
  }
}
