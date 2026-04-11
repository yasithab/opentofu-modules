#!/bin/bash
set -euo pipefail

# =============================================================================
# Tailscale Subnet Router - cloud-init bootstrap (HA mode)
#
# This script runs on every new instance launched by the ASG:
#   1. Disables source/dest check (required for packet forwarding)
#   2. Installs Tailscale and registers with Headscale
#   3. Advertises VPC routes to the tailnet
# =============================================================================

exec > >(tee /var/log/tailscale-setup.log) 2>&1
echo "Starting Tailscale subnet router setup at $(date -u)"

REGION="${aws_region}"
IMDS_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 300")
INSTANCE_ID=$(curl -s -H "X-aws-ec2-metadata-token: $IMDS_TOKEN" http://169.254.169.254/latest/meta-data/instance-id)
echo "Instance: $INSTANCE_ID, Region: $REGION"

dnf install -y jq aws-cli || true

# -----------------------------------------------------------------------------
# 1. Disable source/dest check (subnet router must forward packets)
# -----------------------------------------------------------------------------
echo "Disabling source/dest check..."
for attempt in $(seq 1 5); do
  aws ec2 modify-instance-attribute \
    --instance-id "$INSTANCE_ID" \
    --no-source-dest-check \
    --region "$REGION" && break
  echo "Attempt $attempt failed, retrying..."
  sleep 3
done

# -----------------------------------------------------------------------------
# 2. Enable IP forwarding
# -----------------------------------------------------------------------------
cat > /etc/sysctl.d/99-tailscale.conf <<'SYSCTL'
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
SYSCTL
sysctl -p /etc/sysctl.d/99-tailscale.conf

# -----------------------------------------------------------------------------
# 3. Install Tailscale
# -----------------------------------------------------------------------------
ARCH="${is_arm ? "arm64" : "amd64"}"
VERSION="${tailscale_version}"

curl -fsSL -o /tmp/tailscale.tgz \
  "https://pkgs.tailscale.com/stable/tailscale_$${VERSION}_$${ARCH}.tgz"
tar -xzf /tmp/tailscale.tgz -C /tmp
cp /tmp/tailscale_$${VERSION}_$${ARCH}/tailscale /usr/local/bin/
cp /tmp/tailscale_$${VERSION}_$${ARCH}/tailscaled /usr/local/bin/
rm -rf /tmp/tailscale*

# -----------------------------------------------------------------------------
# 4. Create systemd service
# -----------------------------------------------------------------------------
cat > /etc/systemd/system/tailscaled.service <<'TAILSCALED_SVC'
[Unit]
Description=Tailscale node agent
Documentation=https://tailscale.com/kb/
After=network-online.target
Wants=network-online.target

[Service]
ExecStart=/usr/local/bin/tailscaled --state=/var/lib/tailscale/tailscaled.state --socket=/var/run/tailscale/tailscaled.sock
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
TAILSCALED_SVC

mkdir -p /var/lib/tailscale /var/run/tailscale

systemctl daemon-reload
systemctl enable tailscaled
systemctl start tailscaled

# Wait for tailscaled socket to be ready
for i in $(seq 1 30); do
  [ -S /var/run/tailscale/tailscaled.sock ] && break
  echo "Waiting for tailscaled to start ($i/30)..."
  sleep 2
done

# -----------------------------------------------------------------------------
# 5. Resolve auth key and register with Headscale
# -----------------------------------------------------------------------------
%{ if secrets_manager_arn != "" }
SM_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "${secrets_manager_arn}" \
  --region "$REGION" \
  --query 'SecretString' --output text)
AUTHKEY=$(echo "$SM_JSON" | jq -r '.${secrets_manager_auth_key_field} // empty')
%{ else }
AUTHKEY="${auth_key}"
%{ endif }

if [ -z "$AUTHKEY" ]; then
  echo "ERROR: Failed to resolve Headscale auth key"
  exit 1
fi

/usr/local/bin/tailscale up \
  --login-server "${headscale_url}" \
  --authkey "$AUTHKEY" \
  --advertise-routes="${advertise_routes}" \
%{ if exit_node_enabled }
  --advertise-exit-node \
%{ endif }
  --hostname="${hostname}" \
  --accept-dns=${accept_dns ? "true" : "false"} \
  --reset

echo "Tailscale subnet router registered at $(date -u)"
echo "Headscale server: ${headscale_url}"
echo "Advertised routes: ${advertise_routes}"
echo "Hostname: ${hostname}"
echo ""
echo "NOTE: Routes must be approved on the Headscale server:"
echo "  headscale routes list"
echo "  headscale routes enable --route <id>"

# -----------------------------------------------------------------------------
# 6. CloudWatch Logs Agent (optional)
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
            "file_path": "/var/log/tailscale-setup.log",
            "log_group_name": "${cloudwatch_log_group}",
            "log_stream_name": "{instance_id}/setup",
            "retention_in_days": -1
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

echo "Subnet router setup complete at $(date -u)"
