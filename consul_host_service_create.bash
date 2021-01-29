#!/bin/bash

#Create Consul Host Service config if it doesn't exist
    if [ ! -f /consul/config/host_service.json ]; then
        thishost=`xenstore-read name`
cat <<EOF > /consul/config/host_service.json
{
    "service": {
        "name": "$thishost",
        "tags": [
            "ansible_hosts",
            "xcp_ng_vm"
        ]
    }
}
EOF
    chown consul /consul/config/host_service.json
    fi

#Let's also fix the hostname if it hasn't been set
current_hostname=`hostname`

if [ $current_hostname == "localhost.localdomain" ]; then
    thishost=`xenstore-read name`
    echo $thishost > /etc/hostname
    hostname $thishost
fi