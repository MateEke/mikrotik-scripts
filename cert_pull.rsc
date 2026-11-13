# Installs this device's cert + key for www-ssl and api-ssl from an encrypted pfx on a web server.
# <dev>.serial is checked first, the pfx is only downloaded when it names a different cert.

:local dev "router"
:local url ("https://certs.example.com/" . $dev)
:local f ($dev . ".pfx")
:local tmp "cert-pull-new"
:local want ""
:do {
  :set want ([/tool fetch url=($url . ".serial") check-certificate=yes output=user as-value]->"data")
} on-error={ :log error "cert-pull: serial fetch failed"; :error "cert-pull failed" }
:if ([:len $want] < 16 || [:len $want] > 64) do={ :log error ("cert-pull: bad serial \"" . $want . "\""); :error "cert-pull failed" }
:if (("le-" . $want) != [/ip service get www-ssl certificate]) do={
  :do {
    /tool fetch url=($url . ".pfx") check-certificate=yes dst-path=$f output=file
    :delay 2
    /certificate import file-name=$f name=$tmp passphrase=[/ppp secret get [find name=("cert-pfx-" . $dev)] password]
  } on-error={ /file remove [find name=$f]; :log error "cert-pull: fetch/import failed"; :error "cert-pull failed" }
  /file remove [find name=$f]
  :local new [/certificate find name=$tmp private-key=yes]
  :if ([:len $new] = 1) do={
    :local leaf ("le-" . [/certificate get $new serial-number])
    /certificate set $new name=$leaf
    :foreach c in=[/certificate find name=$tmp] do={ /certificate set $c name=("le-ca-" . [/certificate get $c common-name]) }
    :local old [/ip service get www-ssl certificate]
    /ip service set [find where name="www-ssl" or name="api-ssl"] certificate=$leaf
    :if ($old != "none" && $old != "" && $old != $leaf) do={ /certificate remove [find name=$old] }
    /certificate remove [find where name~"^le-ca-" and expired]
    :log info ("cert-pull: www-ssl now uses " . $leaf)
  } else={ /certificate remove [find name=$tmp]; :log warning ("cert-pull: " . $f . " had no new keyed cert (serial " . $want . ")") }
}
