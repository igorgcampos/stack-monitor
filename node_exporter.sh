#!/bin/bash

# Define usuário dedicado para Node Exporter
sudo useradd --no-create-home --shell /usr/sbin/nologin node_exporter

# Obtém a última versão do Node Exporter
NODE_VER=$(curl -s https://api.github.com/repos/prometheus/node_exporter/releases/latest | grep tag_name | cut -d '"' -f 4 | tr -d v)

# Baixa e instala o Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v${NODE_VER}/node_exporter-${NODE_VER}.linux-amd64.tar.gz
tar -xvzf node_exporter-${NODE_VER}.linux-amd64.tar.gz
sudo mv node_exporter-${NODE_VER}.linux-amd64/node_exporter /usr/local/bin/

# Define permissões de segurança
sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Cria um serviço systemd para Node Exporter
cat <<EOF | sudo tee /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
After=network.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Aplica configurações do systemd e inicia Node Exporter
sudo systemctl daemon-reload
sudo systemctl enable --now node_exporter

echo "Node Exporter instalado e rodando na porta 9100."
