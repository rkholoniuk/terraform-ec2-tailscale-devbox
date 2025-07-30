#!/usr/bin/env bash
set -eux

export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a

# -----------------------------------------------------------
# === 0. Enable SSH Access Early
# -----------------------------------------------------------
mkdir -p /home/ubuntu/.ssh
echo "${ssh_pub_key}" >> /home/ubuntu/.ssh/authorized_keys
chown -R ubuntu:ubuntu /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/authorized_keys

# -----------------------------------------------------------
# === 1. Base System Updates & Common Tools
# -----------------------------------------------------------
apt update -y
apt upgrade -y
apt install -y software-properties-common gnupg curl unzip wget git lsb-release
apt install -y htop jq vim tmux net-tools lsof build-essential ufw

# -----------------------------------------------------------
# === 2. Python 3.11 & Pip (Safe install without overriding system Python)
# -----------------------------------------------------------
add-apt-repository -y ppa:deadsnakes/ppa
apt update -y
apt install -y python3.11 python3.11-venv python3.11-distutils
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.11

# Do NOT override system python3 (Ubuntu uses 3.10 for apt)
# python3.11 available via explicit call or virtualenv

# -----------------------------------------------------------
# === 3. Docker (ARM64)
# -----------------------------------------------------------
curl -fsSL https://get.docker.com | bash
usermod -aG docker ubuntu

# -----------------------------------------------------------
# === 4. CloudWatch Agent (ARM64)
# -----------------------------------------------------------
CWA_URL="https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/arm64/latest/amazon-cloudwatch-agent.deb"
wget -O /tmp/cwa.deb "$CWA_URL"
dpkg -i /tmp/cwa.deb
systemctl enable amazon-cloudwatch-agent

# -----------------------------------------------------------
# === 5. Node.js (ARM)
# -----------------------------------------------------------
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt install -y nodejs

# -----------------------------------------------------------
# === 6. Go (ARM)
# -----------------------------------------------------------
curl -LO https://go.dev/dl/go1.22.3.linux-arm64.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf go1.22.3.linux-arm64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> /etc/profile
echo 'export PATH=$PATH:/usr/local/go/bin' >> /home/ubuntu/.profile
ln -sf /usr/local/go/bin/go /usr/bin/go

# -----------------------------------------------------------
# === 7. ZSH + Oh My Zsh
# -----------------------------------------------------------
apt install -y zsh
chsh -s $(which zsh) ubuntu
sudo -u ubuntu sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
cp /home/ubuntu/.oh-my-zsh/templates/zshrc.zsh-template /home/ubuntu/.zshrc
chown ubuntu:ubuntu /home/ubuntu/.zshrc

# -----------------------------------------------------------
# === 8. SSM Agent (Snap)
# -----------------------------------------------------------
snap wait system seed.loaded
if ! snap list amazon-ssm-agent &>/dev/null; then
    snap install amazon-ssm-agent --classic
fi
snap start amazon-ssm-agent
snap enable amazon-ssm-agent

# -----------------------------------------------------------
# === 9. Auto-Security Updates
# -----------------------------------------------------------
apt install -y unattended-upgrades
systemctl enable unattended-upgrades

# -----------------------------------------------------------
# === 10. Cleanup
# -----------------------------------------------------------
apt autoremove -y
apt clean

# -----------------------------------------------------------
# === 11. Log Versions (use safe direct commands)
# -----------------------------------------------------------
/usr/bin/docker --version > /var/log/docker-version.log
python3.11 --version > /var/log/python-version.log
python3.11 -m pip --version >> /var/log/python-version.log
node -v > /var/log/node-version.log
npm -v >> /var/log/node-version.log
go version > /var/log/go-version.log

# -----------------------------------------------------------
# === 12. Message of the Day
# -----------------------------------------------------------
echo "✅ Devbox ready. Python 3.11, Docker, Node.js, Go, Zsh, SSM, CloudWatch Agent installed." > /etc/motd
