#!/bin/bash
set -e

# === Instalar Docker ===
echo "[INFO] Instalando Docker..."
curl -sSL https://get.docker.com/ | CHANNEL=stable bash

# Instalar Docker Compose plugin (caso não venha junto)
if ! command -v docker compose &> /dev/null; then
  echo "[INFO] Instalando Docker Compose plugin..."
  apt-get update && apt-get install -y docker-compose-plugin
fi

# Instalar Git (se não estiver presente)
if ! command -v git &> /dev/null; then
  echo "[INFO] Instalando Git..."
  apt-get update && apt-get install -y git
fi

# === Variáveis de configuração ===
WG_HOST="SEU_IP_PUBLICO"   # altere para seu IP público ou domínio
WG_PASSWORD="SENHA_FORTE"  # altere para sua senha
BASE_DIR="$HOME/wg-adguard"

# === Criar diretórios de persistência ===
mkdir -p $BASE_DIR/adguard/opt-adguard-work
mkdir -p $BASE_DIR/adguard/opt-adguard-conf
mkdir -p $BASE_DIR/unbound
mkdir -p $BASE_DIR/.wg-easy

# === Gerar docker-compose.yml ===
cat > $BASE_DIR/docker-compose.yml <<EOF
version: "3"

services:
  wg-easy:
    environment:
      - WG_HOST=${WG_HOST}
      - PASSWORD=${WG_PASSWORD}
      - WG_DEFAULT_DNS=10.8.1.3
    image: weejewel/wg-easy
    volumes:
      - "$BASE_DIR/.wg-easy:/etc/wireguard"
    ports:
      - "51820:51820/udp"
      - "51821:51821/tcp"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.ip_forward=1
      - net.ipv4.conf.all.src_valid_mark=1
    networks:
      wg-easy:
        ipv4_address: 10.8.1.2
      
  adguard-unbound:
    container_name: adguard-unbound
    image: ghcr.io/hat3ph/adguard-unbound
    restart: unless-stopped
    hostname: adguard-unbound
    volumes:
      - "$BASE_DIR/adguard/opt-adguard-work:/opt/adguardhome/work"
      - "$BASE_DIR/adguard/opt-adguard-conf:/opt/adguardhome/conf"
      - "$BASE_DIR/unbound:/opt/unbound"
      - "/usr/share/dns:/usr/share/dns"
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "3000:3000/tcp"
      - "80:80/tcp"
      - "5053:5053/tcp"
      - "5053:5053/udp"
    networks:
      wg-easy:
        ipv4_address: 10.8.1.3

networks:
  wg-easy:
    ipam:
      config:
        - subnet: 10.8.1.0/24
EOF

# === Configurar iptables ===
echo "[INFO] Configurando firewall..."
iptables -A INPUT -p udp --dport 51820 -j ACCEPT   # WireGuard
iptables -A INPUT -p tcp --dport 51821 -j ACCEPT   # wg-easy painel
iptables -A INPUT -p tcp --dport 53 -j ACCEPT      # DNS TCP
iptables -A INPUT -p udp --dport 53 -j ACCEPT      # DNS UDP
iptables -A INPUT -p tcp --dport 3000 -j ACCEPT    # AdGuard instalação
iptables -A INPUT -p tcp --dport 80 -j ACCEPT      # AdGuard painel HTTP
iptables -A INPUT -p tcp --dport 5053 -j ACCEPT    # Unbound TCP
iptables -A INPUT -p udp --dport 5053 -j ACCEPT    # Unbound UDP

# Persistir regras iptables
echo "[INFO] Salvando regras iptables..."
iptables-save > /etc/iptables.rules

# Criar serviço systemd para restaurar regras no boot
cat > /etc/systemd/system/iptables-restore.service <<EOF
[Unit]
Description=Restore iptables rules
After=network.target

[Service]
Type=oneshot
ExecStart=/sbin/iptables-restore /etc/iptables.rules
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl enable iptables-restore.service

# === Habilitar IP Forwarding ===
echo "[INFO] Habilitando IP forwarding..."
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf

# === Inicializar Git ===
echo "[INFO] Inicializando repositório Git..."
cd $BASE_DIR
git init
git add docker-compose.yml
git commit -m "Initial commit: WireGuard + AdGuard/Unbound setup"

# === Subir containers ===
echo "[INFO] Subindo containers..."
docker compose up -d

echo "[INFO] Configuração concluída!"
