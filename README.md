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

## Dynamic ipv6 prefix update for firewall

For dynamic ipv6 prefix updates also add:
IPV6 / DHCPv6 Client / pppoe-out / advanced

```
/ipv6 route remove [find gateway=pppoe-out1 vpn=yes]
/delay 2
/system script run dynamic_prefix_update
/delay 1000ms
/system script run cloudflare_ddns_ipv6
```

## Wireguard interface reset

Tools / Netwatch / {{host}} / Down:

```
/system script run wireguard_interface_reset
```
