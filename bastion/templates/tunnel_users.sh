#!/bin/bash
set -euo pipefail

%{ for username, user in tunnel_users ~}
useradd -m -s /usr/sbin/nologin "${username}" 2>/dev/null || true
mkdir -p "/home/${username}/.ssh"
chmod 700 "/home/${username}/.ssh"

%{ if length(user.allowed_tunnels) > 0 ~}
echo 'restrict,port-forwarding,%{ for i, t in user.allowed_tunnels ~}permitopen="${t}"%{ if i < length(user.allowed_tunnels) - 1 ~},%{ endif ~}%{ endfor } ${user.ssh_public_key}' \
  > "/home/${username}/.ssh/authorized_keys"
%{ else ~}
echo 'restrict,port-forwarding ${user.ssh_public_key}' \
  > "/home/${username}/.ssh/authorized_keys"
%{ endif ~}

chmod 600 "/home/${username}/.ssh/authorized_keys"
chown -R "${username}:${username}" "/home/${username}/.ssh"
%{ endfor ~}
