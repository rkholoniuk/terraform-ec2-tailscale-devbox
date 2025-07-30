#!/usr/bin/env bash
set -eux

export DEBIAN_FRONTEND=noninteractive

# === System Update ===
apt update
apt upgrade -y

# === General Variables ===
region="us-east-1"
platform="arm64"

# === CloudWatch Agent ===
wget -q "https://amazoncloudwatch-agent-${region}.s3.${region}.amazonaws.com/ubuntu/${platform}/latest/amazon-cloudwatch-agent.deb" -O /tmp/amazon-cloudwatch-agent.deb
dpkg -i -E /tmp/amazon-cloudwatch-agent.deb

ssmParameterName="AmazonCloudWatch-linux-Tailscale"
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config -m ec2 -c ssm:${ssmParameterName} -s || true

# === Install Tailscale ===
curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled

# === Enable IP Forwarding ===
echo 'net.ipv4.ip_forward = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
echo 'net.ipv6.conf.all.forwarding = 1' | tee -a /etc/sysctl.d/99-tailscale.conf
sysctl -p /etc/sysctl.d/99-tailscale.conf

# === Set Up NAT ===
apt install -y iptables-persistent
iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
iptables-save > /etc/iptables/rules.v4

# === Tailscale Performance Tuning ===
cat <<'EOF' > /etc/networkd-dispatcher/routable.d/50-tailscale
#!/bin/sh
iface="$(ip route show 0/0 | cut -f5 -d' ')"
ethtool -K "$iface" rx-udp-gro-forwarding on rx-gro-list off || true
EOF
chmod +x /etc/networkd-dispatcher/routable.d/50-tailscale

# Setup to reapply at reboot
(crontab -l 2>/dev/null; echo "@reboot /etc/networkd-dispatcher/routable.d/50-tailscale") | crontab -


# === Authenticate and Start Tailscale ===
auth_key="tskey-auth-"
tailscale up \
  --authkey="${auth_key}" \
  --advertise-routes=10.0.0.0/16 \
  --accept-routes \
  --advertise-exit-node
  
# === Final Check ===
tailscale status || true
