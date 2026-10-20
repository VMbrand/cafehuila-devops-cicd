#!/bin/bash
# User data de la EC2 (Amazon Linux 2023, t3.micro): la deja lista para recibir despliegues.
# Se pega en "Advanced details → User data" al lanzar la instancia. Corre UNA vez, como root.
set -euxo pipefail

# 1. Docker
dnf install -y docker
systemctl enable --now docker
usermod -aG docker ec2-user

# 2. Plugin "docker compose" (AL2023 no lo trae en sus repositorios)
mkdir -p /usr/local/lib/docker/cli-plugins
curl -fsSL "https://github.com/docker/compose/releases/download/v2.29.7/docker-compose-linux-$(uname -m)" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# 3. 1 GB de swap: la t3.micro solo tiene 1 GB de RAM y un "pull" grande la puede ahogar
dd if=/dev/zero of=/swapfile bs=1M count=1024
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile swap swap defaults 0 0' >> /etc/fstab

# 4. Carpeta donde el pipeline deja compose.prod.yml
mkdir -p /home/ec2-user/app
chown ec2-user:ec2-user /home/ec2-user/app

echo "LISTA PARA DESPLEGAR" > /home/ec2-user/LISTA.txt
