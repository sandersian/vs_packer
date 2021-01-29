#!/bin/bash
sed -i s/ansible_hosts\",$/ansible_hosts\",\\n\ \ \ \ \ \ \ \ \ \ \ \ \"$1\",/ /consul/config/host_service.json
systemctl restart consul