#!/bin/bash
set -uo pipefail

echo "=== Bastion init started at $(date -u) ==="

export AWS_RETRY_MODE=standard
export AWS_MAX_ATTEMPTS=3

TOKEN=$(curl -sf -X PUT "http://169.254.169.254/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
INSTANCE_ID=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -sf -H "X-aws-ec2-metadata-token: $TOKEN" \
  http://169.254.169.254/latest/meta-data/placement/region)

if [ -z "$INSTANCE_ID" ] || [ -z "$REGION" ]; then
  echo "FATAL: Failed to retrieve instance metadata. Aborting."
  exit 1
fi
echo "Instance=$INSTANCE_ID Region=$REGION"

%{ if eip_allocation_id != "" || persist_ssh_host_keys ~}
echo "Waiting for IAM credentials..."
for i in $(seq 1 30); do
  aws sts get-caller-identity --region "$REGION" > /dev/null 2>&1 && break
  [ "$i" -eq 30 ] && echo "WARNING: IAM credentials not available after 150s"
  sleep 5
done
%{ endif ~}

%{ if length(tunnel_users) > 0 ~}
echo "Creating tunnel users..."
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
echo "User ${username} configured."
%{ endfor ~}
%{ endif ~}

%{ if eip_allocation_id != "" ~}
echo "Associating EIP ${eip_allocation_id}..."
(
  for i in $(seq 1 10); do
    aws ec2 associate-address \
      --instance-id "$INSTANCE_ID" \
      --allocation-id "${eip_allocation_id}" \
      --region "$REGION" \
      --allow-reassociation 2>&1 && echo "EIP associated." && break
    echo "EIP attempt $i/10 failed, retrying in 10s..."
    sleep 10
  done
) &
%{ endif ~}

%{ if persist_ssh_host_keys ~}
SSM_PARAM="${ssh_host_key_ssm_prefix}"

echo "Fetching SSH host keys from SSM..."
_keys_json=""
for i in $(seq 1 5); do
  _keys_json=$(aws ssm get-parameter \
    --name "$SSM_PARAM" \
    --with-decryption \
    --region "$REGION" \
    --cli-connect-timeout 5 \
    --cli-read-timeout 10 \
    --query 'Parameter.Value' \
    --output text 2>&1) && [ -n "$_keys_json" ] && break
  echo "SSM host key attempt $i/5 failed: $_keys_json"
  _keys_json=""
  sleep 5
done

if [ -n "$_keys_json" ]; then
  _installed=0
  for _algo in ed25519 rsa ecdsa; do
    _priv=$(echo "$_keys_json" | jq -r ".$${_algo}.private_key")
    _pub=$(echo "$_keys_json" | jq -r ".$${_algo}.public_key")

    if [ -n "$_priv" ] && [ "$_priv" != "null" ] && [ -n "$_pub" ] && [ "$_pub" != "null" ]; then
      printf '%s\n' "$_priv" > "/etc/ssh/ssh_host_$${_algo}_key"
      printf '%s\n' "$_pub" > "/etc/ssh/ssh_host_$${_algo}_key.pub"
      chmod 600 "/etc/ssh/ssh_host_$${_algo}_key"
      chmod 644 "/etc/ssh/ssh_host_$${_algo}_key.pub"
      _installed=$((_installed + 1))
      echo "Installed $${_algo} host key."
    fi
  done
  unset _priv _pub _algo

  if [ "$_installed" -gt 0 ]; then
    systemctl restart sshd.service
    echo "SSH host keys installed ($_installed types), sshd restarted."
  else
    echo "WARNING: Failed to parse any SSH host keys from SSM. Using OS-generated keys."
  fi
  unset _installed
else
  echo "WARNING: Failed to fetch SSH host keys from SSM. Using OS-generated keys."
fi
unset _keys_json
%{ endif ~}

echo "=== Bastion init completed at $(date -u) ==="
