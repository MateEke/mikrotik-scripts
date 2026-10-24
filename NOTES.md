# Notes

## MTU

Magyar Telekom specific: PPPoE negotiates 1500, but some paths inside their network (traffic coming in via Deutsche Telekom) only carry 1492 and drop bigger packets without ICMP (Azure Front Door, AWS). So:

```
/interface pppoe-client set pppoe-out1 max-mtu=1492 max-mru=1492
/ipv6 nd set [find] mtu=1492
/ipv6 firewall mangle add chain=forward protocol=tcp tcp-flags=syn out-interface=pppoe-out1 tcp-mss=1433-65535 action=change-mss new-mss=1432 passthrough=yes
```

`change-tcp-mss` in the PPP profile only clamps ipv4, hence the mangle rule.

To check if you are affected, force a 1500 MTU for a single destination from a Linux box on the LAN and see if it hangs (with 1492 it works):

```
ip -6 route add <server-ip>/128 via <router-link-local> dev <interface> mtu 1500
curl -6 --resolve <host>:443:[<server-ip>] https://<host>/
ip -6 route del <server-ip>/128
```

Or from an outside host (e.g. a VPS) towards your public IP: `ping -M do -s 1464` (1492 byte packet) gets through, `-s 1466` doesn't, and no "frag needed" comes back.

## DNS

My LG TV does reverse lookups for the whole subnet every 5 minutes, which hit the DoH limit (`DoH max concurrent queries reached`):

```
/ip dns set doh-max-concurrent-queries=150 max-concurrent-queries=200
```

An NXDOMAIN static entry for `168.192.in-addr.arpa` would keep these local, but it also breaks the PTR answers for static entries.
