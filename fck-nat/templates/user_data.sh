#!/bin/sh

# Write fck-nat configuration
: > /etc/fck-nat.conf
echo "eni_id=${eni_id}" >> /etc/fck-nat.conf
echo "eip_id=${eip_id}" >> /etc/fck-nat.conf

# Kernel tuning for NAT performance
%{ if conntrack_max > 0 ~}
echo "nf_conntrack_max=${conntrack_max}" >> /etc/fck-nat.conf
sysctl -w net.netfilter.nf_conntrack_max=${conntrack_max}
%{ endif ~}
%{ if local_port_range != "" ~}
echo "ip_local_port_range=${local_port_range}" >> /etc/fck-nat.conf
sysctl -w net.ipv4.ip_local_port_range="${local_port_range}"
%{ endif ~}

service fck-nat restart
