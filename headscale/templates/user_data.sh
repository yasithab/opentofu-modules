#!/bin/bash
set -euo pipefail

# =============================================================================
# Headscale ${headscale_version}  - cloud-init bootstrap (HA mode)
#
# This script runs on every new instance launched by the ASG:
#   1. Self-associates the Elastic IP
#   2. Self-attaches the persistent EBS data volume
#   3. Installs and configures Headscale
#   4. Optionally sets up a built-in subnet router
# =============================================================================

exec > >(tee /var/log/headscale-setup.log) 2>&1
echo "Starting Headscale setup at $(date -u)"

REGION="${aws_region}"
IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
echo "Instance: $INSTANCE_ID, Region: $REGION"

dnf install -y jq aws-cli || true

# -----------------------------------------------------------------------------
# 1. Self-associate Elastic IP (stable public address across replacements)
# -----------------------------------------------------------------------------
%{ if eip_allocation_id != "" }
echo "Associating EIP ${eip_allocation_id}..."
for attempt in $(seq 1 5); do
  aws ec2 associate-address \
    --instance-id "$INSTANCE_ID" \
    --allocation-id "${eip_allocation_id}" \
    --allow-reassociation \
    --region "$REGION" && break
  echo "EIP association attempt $attempt failed, retrying..."
  sleep 5
done
echo "EIP associated."
%{ endif }

# -----------------------------------------------------------------------------
# 2. Self-attach and mount EBS data volume (persistent state)
# -----------------------------------------------------------------------------
DATA_DIR="${data_dir}"
%{ if use_data_volume }
VOLUME_ID="${data_volume_id}"
echo "Attaching data volume $VOLUME_ID"

# Wait for the volume to be available (may still be detaching from a terminated instance)
for i in $(seq 1 60); do
  STATE=$(aws ec2 describe-volumes --volume-ids "$VOLUME_ID" --region "$REGION" \
    --query 'Volumes[0].State' --output text 2>/dev/null || echo "unknown")
  if [ "$STATE" = "available" ]; then
    break
  elif [ "$STATE" = "in-use" ]; then
    # Check if it's already attached to this instance
    ATTACHED_TO=$(aws ec2 describe-volumes --volume-ids "$VOLUME_ID" --region "$REGION" \
      --query 'Volumes[0].Attachments[0].InstanceId' --output text 2>/dev/null || echo "")
    if [ "$ATTACHED_TO" = "$INSTANCE_ID" ]; then
      echo "Volume already attached to this instance"
      break
    fi
    echo "Volume attached to $ATTACHED_TO, waiting for detach ($i/60)..."
  else
    echo "Volume state: $STATE ($i/60)."
  fi
  sleep 5
done

# Attach the volume
aws ec2 attach-volume \
  --volume-id "$VOLUME_ID" \
  --instance-id "$INSTANCE_ID" \
  --device /dev/xvdf \
  --region "$REGION" 2>/dev/null || true

# Wait for the block device to appear
for i in $(seq 1 30); do
  [ -b /dev/xvdf ] && break
  echo "Waiting for /dev/xvdf ($i/30)..."
  sleep 2
done

if [ -b /dev/xvdf ]; then
  # Format only if not already formatted (first-time setup)
  if ! blkid /dev/xvdf | grep -q ext4; then
    echo "Formatting new data volume..."
    mkfs.ext4 -L headscale-data /dev/xvdf
  fi
  mkdir -p "$DATA_DIR"
  mount /dev/xvdf "$DATA_DIR"
  grep -q headscale-data /etc/fstab || \
    echo "LABEL=headscale-data $DATA_DIR ext4 defaults,nofail 0 2" >> /etc/fstab
  echo "Data volume mounted at $DATA_DIR"
else
  echo "WARNING: /dev/xvdf not found after 60s, using root volume"
  mkdir -p "$DATA_DIR"
fi
%{ else }
mkdir -p "$DATA_DIR"
%{ endif }

# Ensure subdirectories exist
mkdir -p "$DATA_DIR/run" "$DATA_DIR/cache"

# -----------------------------------------------------------------------------
# 3. Install Headscale
# -----------------------------------------------------------------------------
ARCH="${is_arm ? "arm64" : "amd64"}"
VERSION="${headscale_version}"

# Download binary (official standalone method - https://headscale.net/stable/setup/install/official/)
curl -fsSL -o /usr/bin/headscale \
  "https://github.com/juanfont/headscale/releases/download/v$${VERSION}/headscale_$${VERSION}_linux_$${ARCH}"
chmod +x /usr/bin/headscale

# Create headscale user with home directory (per official docs)
useradd \
  --create-home \
  --home-dir /var/lib/headscale/ \
  --system \
  --user-group \
  --shell /usr/sbin/nologin \
  headscale 2>/dev/null || true
mkdir -p /etc/headscale /var/run/headscale

# Create systemd service (per official docs)
cat > /etc/systemd/system/headscale.service <<'HEADSCALE_SVC'
[Unit]
Description=Headscale coordination server
Documentation=https://github.com/juanfont/headscale
After=network-online.target
Wants=network-online.target

[Service]
User=headscale
Group=headscale
ExecStart=/usr/bin/headscale serve
WorkingDirectory=/var/lib/headscale
RuntimeDirectory=headscale
ReadWritePaths=/var/lib/headscale /var/run/headscale ${data_dir}
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
HEADSCALE_SVC

# -----------------------------------------------------------------------------
# 4. Configuration
# -----------------------------------------------------------------------------
cat > /etc/headscale/config.yaml <<'HEADSCALE_CONFIG'
server_url: ${server_url}
listen_addr: 0.0.0.0:443
metrics_listen_addr: 127.0.0.1:${metrics_port}

%{ if base_domain != "" }
dns:
  base_domain: ${base_domain}
  magic_dns: true
  nameservers:
    global:
      - 1.1.1.1
      - 8.8.8.8
%{ else }
dns:
  magic_dns: false
  nameservers:
    global:
      - 1.1.1.1
      - 8.8.8.8
%{ endif }

prefixes:
  v4: ${split(",", ip_prefixes)[0]}
%{ if length(split(",", ip_prefixes)) > 1 }
  v6: ${split(",", ip_prefixes)[1]}
%{ endif }

database:
  type: sqlite
  sqlite:
    path: ${data_dir}/db.sqlite

unix_socket: /var/run/headscale/headscale.sock
unix_socket_permission: "0770"

noise:
  private_key_path: ${data_dir}/noise_private.key

derp:
  server:
%{ if derp_enabled }
    enabled: true
    private_key_path: ${data_dir}/derp_server_private.key
    automatically_add_embedded_derp_region: true
    stun_listen_addr: 0.0.0.0:${derp_stun_port}
%{ else }
    enabled: false
%{ endif }
  urls:
    - https://controlplane.tailscale.com/derpmap/default
  auto_update_enabled: true
  update_frequency: 24h

%{ if use_letsencrypt }
tls_letsencrypt_hostname: ${trimprefix(trimprefix(server_url, "https://"), "http://")}
tls_letsencrypt_listen: :80
tls_letsencrypt_cache_dir: ${data_dir}/cache
tls_letsencrypt_challenge_type: HTTP-01
%{ endif }

ephemeral_node_inactivity_timeout: 5m

log:
  level: info

policy:
  mode: database

HEADSCALE_CONFIG

# -----------------------------------------------------------------------------
# 5. Fetch secrets from Secrets Manager (optional)
# -----------------------------------------------------------------------------
%{ if secrets_manager_arn != "" }
echo "Fetching secrets from Secrets Manager..."
SM_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "${secrets_manager_arn}" \
  --region "$REGION" \
  --query 'SecretString' --output text)
%{ endif }

# -----------------------------------------------------------------------------
# 6. OIDC configuration (optional)
# -----------------------------------------------------------------------------
%{ if oidc_issuer != "" }

# Resolve OIDC client secret
%{ if secrets_manager_arn != "" }
OIDC_SECRET=$(echo "$SM_JSON" | jq -r '.${secrets_manager_oidc_key} // empty')
if [ -z "$OIDC_SECRET" ]; then
  echo "ERROR: Key '${secrets_manager_oidc_key}' not found in Secrets Manager secret"
  exit 1
fi
%{ else }
OIDC_SECRET="${oidc_client_secret}"
%{ endif }

cat >> /etc/headscale/config.yaml <<OIDC_CONFIG
oidc:
  issuer: ${oidc_issuer}
  client_id: ${oidc_client_id}
  client_secret: $OIDC_SECRET
  expiry: ${oidc_expiry}
%{ if oidc_allowed_users != "" }
  allowed_users:
%{ for user in split(",", oidc_allowed_users) }
    - ${user}
%{ endfor }
%{ endif }
OIDC_CONFIG
%{ endif }

# -----------------------------------------------------------------------------
# 7. ACL policy (optional)
# -----------------------------------------------------------------------------
%{ if acl_policy != "" }
cat > "$DATA_DIR/acl_policy.json" <<'ACL_POLICY'
${acl_policy}
ACL_POLICY
# Policy is applied after Headscale starts (step 8a below)
%{ endif }

# -----------------------------------------------------------------------------
# 8. Permissions and systemd
# -----------------------------------------------------------------------------
chown -R headscale:headscale "$DATA_DIR"

# Override systemd to use our data directory
mkdir -p /etc/systemd/system/headscale.service.d
cat > /etc/systemd/system/headscale.service.d/override.conf <<EOF
[Service]
# Allow binding to privileged ports (443, 80)
AmbientCapabilities=CAP_NET_BIND_SERVICE
EOF

systemctl daemon-reload
systemctl enable headscale
systemctl start headscale

echo "Headscale coordination server started at $(date -u)"
echo "Server URL: ${server_url}"

# Wait for Headscale to be ready
for i in $(seq 1 30); do
  headscale status > /dev/null 2>&1 && break
  echo "Waiting for Headscale to start ($i/30)..."
  sleep 2
done

# Apply ACL policy (must be after Headscale starts, before key generation)
%{ if acl_policy != "" }
echo "Applying ACL policy..."
headscale policy set -f "$DATA_DIR/acl_policy.json"
echo "ACL policy applied."
%{ endif }

# -----------------------------------------------------------------------------
# 9. Publish pre-auth key to Secrets Manager (for cross-account subnet routers)
# -----------------------------------------------------------------------------
%{ if publish_auth_key }
echo "Generating pre-auth key for external subnet routers..."
headscale users create subnet-routers 2>/dev/null || true
SR_USER_ID=$(headscale users list -o json 2>/dev/null | jq -r '.[] | select(.name == "subnet-routers") | .id')
EXTERNAL_KEY=$(headscale preauthkeys create --user "$SR_USER_ID" --tags tag:router --reusable --ephemeral --expiration 87600h -o json 2>/dev/null | jq -r '.key // empty')

if [ -n "$EXTERNAL_KEY" ]; then
  # Read current secret, merge in the new key, write back
  CURRENT_SECRET=$(aws secretsmanager get-secret-value \
    --secret-id "${secrets_manager_arn}" \
    --region "$REGION" \
    --query 'SecretString' --output text 2>/dev/null || echo '{}')

  UPDATED_SECRET=$(echo "$CURRENT_SECRET" | jq --arg key "$EXTERNAL_KEY" '.headscale_auth_key = $key')

  aws secretsmanager put-secret-value \
    --secret-id "${secrets_manager_arn}" \
    --region "$REGION" \
    --secret-string "$UPDATED_SECRET"

  echo "Pre-auth key published to Secrets Manager"
else
  echo "WARNING: Failed to generate external pre-auth key"
fi
%{ endif }

# -----------------------------------------------------------------------------
# 10. Built-in Subnet Router (optional)
# -----------------------------------------------------------------------------
%{ if subnet_router_enabled }
echo "Setting up built-in subnet router..."

# Disable source/dest check so the instance can forward packets for other IPs
aws ec2 modify-instance-attribute \
  --instance-id "$INSTANCE_ID" \
  --no-source-dest-check \
  --region "$REGION"

# Install Tailscale client
TS_ARCH="${is_arm ? "arm64" : "amd64"}"
TS_VERSION="${tailscale_version}"
curl -fsSL -o /tmp/tailscale.tgz \
  "https://pkgs.tailscale.com/stable/tailscale_$${TS_VERSION}_$${TS_ARCH}.tgz"
tar -xzf /tmp/tailscale.tgz -C /tmp
cp /tmp/tailscale_$${TS_VERSION}_$${TS_ARCH}/tailscale /usr/local/bin/
cp /tmp/tailscale_$${TS_VERSION}_$${TS_ARCH}/tailscaled /usr/local/bin/
rm -rf /tmp/tailscale*

# Create systemd service for tailscaled
cat > /etc/systemd/system/tailscaled.service <<'TAILSCALED_SVC'
[Unit]
Description=Tailscale node agent
Documentation=https://tailscale.com/kb/
After=network-online.target headscale.service
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock
Restart=on-failure

[Install]
WantedBy=multi-user.target
TAILSCALED_SVC

mkdir -p /var/lib/tailscale /var/run/tailscale

# Enable IP forwarding
echo 'net.ipv4.ip_forward = 1' > /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' >> /etc/sysctl.d/99-tailscale.conf
sysctl -p /etc/sysctl.d/99-tailscale.conf

systemctl daemon-reload
systemctl enable tailscaled
systemctl start tailscaled

# Wait for tailscaled to be ready
for i in $(seq 1 15); do
  /usr/local/bin/tailscale status > /dev/null 2>&1 && break
  sleep 2
done

# Create the subnet router user and pre-auth key
headscale users create "${subnet_router_user}" 2>/dev/null || true
BUILTIN_USER_ID=$(headscale users list -o json 2>/dev/null | jq -r '.[] | select(.name == "${subnet_router_user}") | .id')
AUTHKEY=$(headscale preauthkeys create --user "$BUILTIN_USER_ID" --tags tag:router --reusable --ephemeral --expiration 87600h -o json 2>/dev/null | jq -r '.key // empty')
if [ -z "$AUTHKEY" ]; then
  echo "ERROR: Failed to create pre-auth key for subnet router"
  exit 1
fi

# Register the Tailscale client with Headscale
/usr/local/bin/tailscale up \
  --login-server "${server_url}" \
  --authkey "$AUTHKEY" \
%{ if advertise_routes != "" ~}
  --advertise-routes="${advertise_routes}" \
%{ endif ~}
%{ if exit_node_enabled ~}
  --advertise-exit-node \
%{ endif ~}
  --hostname="$(hostname)-subnet-router" \
  --accept-dns=false

# Auto-approve advertised routes
sleep 5
ROUTES=$(headscale routes list -o json 2>/dev/null | jq -r '.[] | select(.advertised == true and .enabled == false) | .id' || true)
for route_id in $ROUTES; do
  headscale routes enable --route "$route_id" 2>/dev/null || true
  echo "Enabled route: $route_id"
done

echo "Subnet router registered and routes enabled."
%{ endif }

# -----------------------------------------------------------------------------
# 11. CloudWatch Logs Agent (optional)
# -----------------------------------------------------------------------------
%{ if cloudwatch_logs_enabled }
echo "Setting up CloudWatch agent..."

dnf install -y amazon-cloudwatch-agent || true

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json <<'CW_CONFIG'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/headscale-setup.log",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/setup",
            "retention_in_days": -1
          },
          {
            "file_path": "/var/log/messages",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/headscale",
            "retention_in_days": -1,
            "filters": [{ "type": "include", "expression": "headscale" }]
          }
        ]
      }
    }
  }
}
CW_CONFIG

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

echo "CloudWatch agent started."
%{ endif }

echo "Headscale setup complete at $(date -u)"
