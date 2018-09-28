## using data groups to do pool selection by uri or host and dynamic TLS as well as maintenance pages ##
#
# Requirements:
#   datagroup with formatting for uri or pool
#   example: 
#       "/pool1" := "/Common/pool1",
#       "/pool2" := "/Common/pool2",
#   Rename
#       find and replace rulename with your irulename
#   Create ifiles
#       create ifile objects to support maintenance page objects
#   Pool members
#       default SSL/TLS ports 80/443 are accounted for, if you need non standard ports extend the LB::server port check.
#   
# when rule init
# set options
when RULE_INIT {
# set your datagroup name
    set static::rulename_datagroup "uri_to_string_dg1"
# set 1 debug on 0 debug off
    set static::rulename_debug "1"
# set default pool
    set static::rulename_default_pool "/Common/pool4"
# use uri, uri_lower, host, host_lower. mutually exclusive options
    set static::rulename_host_select "0"
    set static::rulename_host_lower_select "0"
    set static::rulename_uri_select "0"
    set static::rulename_uri_lower_select "1"
}
# when http request
# check URI or HOST with $datagroup
# return pool
when HTTP_REQUEST {
# set parameters
    set dataGroup $static::rulename_datagroup
    if {$static::rulename_host_select} {
        set host [HTTP::host]
    }
    if {$static::rulename_host_lower_select} {
        set host [string tolower [HTTP::host]]
    }
    if {$static::rulename_uri_select} {
        set uri [HTTP::uri]
    }
    if {$static::rulename_uri_lower_select} {
        set uri [string tolower [HTTP::uri]]
    }

#Respond with hostedcontent or ifiles
    switch -glob [string tolower $uri] {
            "/maintenance.css" {HTTP::respond 200 content [ifile get "maintenance.css"] noserver "Content-type" "text/css"}
            "/maintenance_beasts.jpg" {HTTP::respond 200 content [ifile get "maintenance_beasts.jpg"] noserver "Content-type" "image/jpeg"}
            "/isitthef5" {HTTP::respond 200 content [ifile get "angry_toad.jpg"] noserver "Content-type" "image/jpeg"}
        }
#
#
    if {($static::rulename_host_select) || ($static::rulename_host_lower_select)} {
## by host ##
#
# Check requested host header
        if { [class match $host eq $dataGroup] }{
                pool [class lookup $host $dataGroup]
                # check selected pool status
                if { [active_members [LB::server pool]] == 0 } {
                    if {$static::rulename_debug}{log local0. "[LB::server pool] was down"}
                    HTTP::respond 200 content [ifile get "maintenance.html"] noserver "Content-type" "text/html"
                } else {
                    set member [LB::select]
                    eval $member
                    #log local0. "The LB choice is: $member"
                    if {[LB::server port] == 80}{
                        if {$static::rulename_debug}{log local0. "tls offloading, pool: [LB::server pool], port: [LB::server port]"}
                        set usessl 0
                    } else {
                        if {$static::rulename_debug}{log local0. "tls bridging, pool: [LB::server pool], port: [LB::server port]"}
                        set usessl 1
                    }
                }
                #
            } else {
                # default pool for clients with no match
                # can be set here or in the virtual server resources tab
                # could use redirect or other page with ifiles here
                pool $static::rulename_default_pool
                set member [LB::select]
                eval $member
                #log local0. "The LB choice is: $member"
                set usessl 1
                if {$static::rulename_debug}{log local0. "no match - tls bridging, pool: [LB::server pool], port: [LB::server port]"}
            }
    }
        
#
#
    if {($static::rulename_uri_select) || ($static::rulename_uri_lower_select)} {
## by uri ##
#
# Check requested uri
    if { [class match $uri eq $dataGroup] }{
        pool [class lookup $uri $dataGroup]
        # check selected pool status
        if { [active_members [LB::server pool]] == 0 } {
            if {$static::rulename_debug}{log local0. "[LB::server pool] was down"}
            # redirects if needed
            # HTTP::redirect "https://[getfield [HTTP::host] ":" 1]/someotherpath"
            # HTTP::redirect "https://host.domain.com/down"
            #respond directly with ifiles
            HTTP::respond 200 content [ifile get "maintenance.html"] noserver "Content-type" "text/html"
        } else {
            set member [LB::select]
            eval $member
            #log local0. "The LB choice is: $member"
            if {[LB::server port] == 80}{
                if {$static::rulename_debug}{log local0. "tls offloading, pool: [LB::server pool], port: [LB::server port]"}
                set usessl 0
            } else {
                if {$static::rulename_debug}{log local0. "tls bridging, pool: [LB::server pool], port: [LB::server port]"}
                set usessl 1
            }
        }
        #
    } else {
        # default pool for clients with no match
        # can be set here or in the virtual server resources tab
        # could use redirect or other page with ifiles here
        pool $static::rulename_default_pool
        set member [LB::select]
        eval $member
        #log local0. "The LB choice is: $member"
        set usessl 1
        if {$static::rulename_debug}{log local0. "no match - tls bridging, pool: [LB::server pool], port: [LB::server port]"}
    }
    }
        
}
# when server connected
# disable ssl for offloaded pools
when SERVER_CONNECTED {
  if { $usessl == 0 } {
    SSL::disable
  }
}