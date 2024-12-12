# mikrotik-scripts

## Cloudflare DDNS

In PPP / Profile / default / Scripts / On Up add:

```
:delay 10000ms;
/system script run cloudflare_ddns_ipv4
:delay 1000ms;
/system script run cloudflare_ddns_ipv6
:delay 1000ms;
/ip cloud force-update
```

For dynamic ipv6 prefix updates also add:
IPV6 / DHCPv6 Client / pppoe-out / advanced

```
/ipv6 route remove [find gateway=pppoe-out1 vpn=yes]
/delay 2
/system script run dynamic_prefix_update
/delay 1000ms
/system script run cloudflare_ddns_ipv6
```
