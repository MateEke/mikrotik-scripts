# mikrotik-scripts

Scripts for my RouterOS 7 setup (PPPoE with dynamic IPv4 and DHCPv6 prefix delegation).
Secrets are replaced with `##SECRET&&`.

## Cloudflare DDNS

One copy of the script per DNS record (e.g. `cloudflare_ddns_ipv4`, `cloudflare_ddns_ipv6`).

The API token is read from a disabled ppp secret, so it doesn't end up in `/export` (script sources aren't hidden as sensitive). Token permission: Zone / DNS / Edit for the zone.

```
/ppp secret add name=cf-token disabled=yes password="##SECRET&&"
```

The scripts need the `sensitive` policy to read it.

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

Updates the prefix of ipv6 address list entries with a comment like `dynamic prefix "bridge"`.

IPV6 / DHCPv6 Client / pppoe-out1 / advanced / script:

```
/delay 10
/system script run dynamic_prefix_update;
/delay 1000ms
/system script run cloudflare_ddns_ipv6;
```

The client script doesn't run on every renewal, so I also run the same every hour from a scheduler.

## PD watchdog

Workaround for a RouterOS 7.25 bug (SUP-226776): after some DHCPv6-PD renewals the from-pool address stays in the config, but the router can't use it anymore. The script pings the address every minute and disables/enables it if needed. Remove it once the bug is fixed.

```
/system scheduler add name=pd-watchdog interval=1m start-time=startup policy=read,write,test on-event="/system script run pd-watchdog"
```

## Wireguard interface reset

Tools / Netwatch / {{host}} / Down:

```
/system script run wireguard_interface_reset
```

The script switches between two listen ports, so allow both in the input firewall.
