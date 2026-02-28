#!/usr/bin/env bash
set -euo pipefail

# Bootstrap a fresh Ubuntu server for Docker Compose deployments.
# Run this script ON THE SERVER (or over SSH).

if [[ "${EUID}" -ne 0 ]]; then
  echo "Please run as root (sudo ./scripts/bootstrap-ubuntu.sh [deploy-user])"
  exit 1
fi

DEPLOY_USER="${1:-${SUDO_USER:-}}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https rsync git ufw fail2ban

install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

ARCH="$(dpkg --print-architecture)"
CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin || \
apt-get install -y docker.io docker-compose-v2

systemctl enable --now docker

if [[ -n "$DEPLOY_USER" ]] && id "$DEPLOY_USER" >/dev/null 2>&1; then
  groupadd -f docker
  usermod -aG docker "$DEPLOY_USER"
  echo "Added $DEPLOY_USER to docker group."
fi

# Minimal firewall profile
ufw allow OpenSSH || true
ufw allow 8080/tcp || true
ufw --force enable || true

systemctl enable --now fail2ban || true

echo "✅ Bootstrap complete."
echo "Next steps:"
echo "1) Re-login if user was added to docker group"
echo "2) Test: docker --version && docker compose version"
echo "3) Deploy from your workstation with ./scripts/deploy-vm.sh"
