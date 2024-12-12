################# Variables #################

# Print debug output
:local CFdebug "false"
# Use mikrotik cloud IP
:local CFcloud "false"
# Interface to get IP from if not using cloud
:local WANInterface "pppoe-out1"
# IP version
:local ipVersion 4
# ipv6 pool (needed only for ipv6)
:local ipv6Pool "ipv6"
# ipv6 interface (needed only for ipv6)
:local ipv6Interface "bridge"
# Domain to be updated (only for logging)
:local CFdomain "##SECRET&&"
# Cloudflare API token
:local CFtkn "##SECRET&&"
# Cloudflare zone id
:local CFzoneid "##SECRET&&"
# Cloudflare dns entry id
:local CFid "##SECRET&&"

#########################################################################
########################  DO NOT EDIT BELOW  ############################
#########################################################################

:log info "Updating $CFdomain ..."

################# Internal variables #################
:local previousIP ""
:local WANip ""
:local fileName "$CFdomain_ipv$ipVersion_ddns.tmp.txt"

################# Build CF API Url (v4) #################
:local CFurl "https://api.cloudflare.com/client/v4/zones/"
:set CFurl ($CFurl . "$CFzoneid/dns_records/$CFid");
 
################# Get or set previous IP-variables #################
:if ($CFcloud = "true") do={
    :if ($ipVersion = 6) do={ 
        :set WANip [/ip cloud get public-address-ipv6]
    } else={
        :set WANip [/ip cloud get public-address]
    }  
};

:if ($CFcloud = "false") do={
    :local currentIP ""
    :if ($ipVersion = 6) do={ 
        :set currentIP [/ipv6/address get [:pick [find global interface=$ipv6Interface from-pool=$ipv6Pool] 0 ] address];
    } else={
        :set currentIP [/ip address get [/ip address find interface=$WANInterface ] address];
    }
    :set WANip [:pick $currentIP 0 [:find $currentIP "/"]];
};

:if ([/file find name=$fileName] = "") do={
    :log error "No previous ip address file found, createing..."
    :set previousIP $WANip;
    :execute script=":put $WANip" file=$fileName;
    :log info ("CF: Updating CF, setting $CFdomain = $WANip")
    /tool fetch http-method=patch mode=https url=$CFurl output=user as-value http-header-field="Authorization: Bearer $CFtkn,Content-Type: application/json" http-data="{\"content\":\"$WANip\"}"
	:log info ("CF: Updated $CFdomain")
} else={
    :if ( [/file get [/file find name=$fileName] size] > 0 ) do={ 
        :global content [/file get [/file find name=$fileName] contents] ;
        :global contentLen [ :len $content ] ;  
        :global lineEnd 0;
        :global line "";
        :global lastEnd 0;   
        :set lineEnd [:find $content "\n" $lastEnd ] ;
        :set line [:pick $content $lastEnd $lineEnd] ;
        :set lastEnd ( $lineEnd + 1 ) ;   
        :if ( [:pick $line 0 1] != "#" ) do={
            :set previousIP [:pick $line 0 $lineEnd ];
            :set previousIP [:pick $previousIP 0 [:find $previousIP "\r"]];
        }
    }
}

######## Write debug info to log #################
:if ($CFdebug = "true") do={
    :log info ("CF: fileName = $fileName")
    :log info ("CF: hostname = $CFdomain")
    :log info ("CF: previousIP = $previousIP")
    :log info ("CF: WANip = $WANip")
    :log info ("CF: CFurl = $CFurl&content=$WANip")
    :log info ("CF: Command = \"/tool fetch http-method=patch mode=https url=\"$CFurl\" http-header-field="Authorization:Bearer $CFtkn,content-type:application/json" output=none http-data=\"{\"content\":\"$WANip\"}\"")
};
  
######## Compare and update CF if necessary #####
:if ($previousIP != $WANip) do={
    :log info ("CF: Updating CF, setting $CFdomain = $WANip")
    /tool fetch http-method=patch mode=https url=$CFurl output=user as-value http-header-field="Authorization: Bearer $CFtkn,Content-Type: application/json" http-data="{\"content\":\"$WANip\"}"
    :log info ("CF: Updated $CFdomain")
    /ip dns cache flush
    :if ( [/file get [/file find name=$fileName] size] > 0 ) do={
        /file remove $fileName
        :execute script=":put $WANip" file=$fileName
    }
} else={
    :log info "CF: No Update Needed!"
}