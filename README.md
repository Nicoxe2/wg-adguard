# 🚀 VPN + DNS AdGuard/Unbound com Docker

Este projeto automatiza a instalação e configuração de um servidor **WireGuard VPN** com interface web (`wg-easy`) integrado ao **AdGuard Home + Unbound** para DNS seguro e filtragem de anúncios.

## 📦 Funcionalidades
- Instalação automática do **Docker** e **Docker Compose**
- Configuração do **WireGuard** com painel web (`wg-easy`)
- DNS seguro com **AdGuard Home** + **Unbound**
- Firewall configurado via `iptables` com regras persistentes
- Versionamento com **Git** para acompanhar mudanças
- Containers sob rede interna `10.8.1.0/24`

## 🛠️ Requisitos
- Servidor Linux (Ubuntu/Debian recomendado)
- Acesso root ou sudo
- IP público ou domínio apontado para o servidor

## ⚙️ Instalação
Clone este repositório e execute o script:

```bash
git clone https://github.com/Nicoxe2/wg-adguard.git
cd wg-adguard
chmod +x setup.sh
./setup.sh
