#!/bin/bash
#Add Consul User
useradd -r -M consul

#Create Consul Area
mkdir -p /consul/config && chown consul /consul/config
mkdir -p /consul/data && chown consul /consul/data
chown consul /consul
chmod -R 700 /consul

#Create Consul Service
cat <<EOF > /etc/systemd/system/consul.service
[Unit]
Description=Consul Agent
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=consul
ExecStart=/usr/local/bin/consul agent -config-dir=/consul/config -data-dir=/consul/data -retry-join=$CONSUL_JOIN_IP1 --retry-join=$CONSUL_JOIN_IP2 -retry-join=$CONSUL_JOIN_IP3 -domain=$CONSUL_DOMAIN

[Install]
WantedBy=multi-user.target
EOF

#Create Consul Config
cat <<EOF > /consul/config/consul.json
{
  "skip_leave_on_interrupt": true,
  "verify_incoming": false,
  "verify_outgoing": true,
  "verify_server_hostname": true,
  "ca_file": "/etc/ssl/certs/local_CA.crt",
  "auto_encrypt": {
    "tls": true
  },
  "encrypt": "$CONSUL_ENC_KEY",
  "encrypt_verify_incoming": true,
  "encrypt_verify_outgoing": true,
  "acl": {
    "enabled": true,
    "default_policy": "deny",
    "enable_token_persistence": true,
    "tokens": {
      "default": "$CONSUL_TOKEN"
    }
  }
}
EOF

#Create one-time service description for consul host service
cat <<EOF > /etc/systemd/system/consul_hostsvc.service
[Unit]
Description=Consul Host Service Creation
Before=consul.service
StartLimitIntervalSec=0

[Service]
Type=oneshot
User=root
ExecStart=/usr/local/bin/consul_host_service_create.bash
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

#Enable Service
chmod u+x /usr/local/bin/consul_host_service_create.bash
systemctl enable consul_hostsvc
systemctl enable consul