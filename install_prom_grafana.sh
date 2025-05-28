#!/bin/bash

# Atualiza os pacotes do sistema
sudo apt update && sudo apt upgrade -y

# Adiciona usuário para Prometheus e Grafana (sem shell de login por segurança)
sudo useradd --no-create-home --shell /usr/sbin/nologin prometheus
sudo useradd --no-create-home --shell /usr/sbin/nologin grafana

# Cria diretórios necessários
sudo mkdir -p /etc/prometheus /var/lib/prometheus
sudo chown prometheus:prometheus /etc/prometheus /var/lib/prometheus

# Baixa e instala Prometheus (verifica sempre a versão mais recente)
PROM_VERSION=$(curl -s https://api.github.com/repos/prometheus/prometheus/releases/latest | grep tag_name | cut -d '"' -f 4 | tr -d v)
wget https://github.com/prometheus/prometheus/releases/download/v${PROM_VERSION}/prometheus-${PROM_VERSION}.linux-amd64.tar.gz

# Extrai e move arquivos para locais adequados
tar -xvzf prometheus-${PROM_VERSION}.linux-amd64.tar.gz
sudo mv prometheus-${PROM_VERSION}.linux-amd64/prometheus /usr/local/bin/
sudo mv prometheus-${PROM_VERSION}.linux-amd64/promtool /usr/local/bin/
sudo mv prometheus-${PROM_VERSION}.linux-amd64/consoles /etc/prometheus
sudo mv prometheus-${PROM_VERSION}.linux-amd64/console_libraries /etc/prometheus

# Define permissões de segurança
sudo chown -R prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool /etc/prometheus

# Cria um arquivo de configuração do Prometheus
cat <<EOF | sudo tee /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']
EOF

# Define permissões seguras para o arquivo de configuração
sudo chown prometheus:prometheus /etc/prometheus/prometheus.yml
sudo chmod 640 /etc/prometheus/prometheus.yml

# Cria um serviço systemd para Prometheus
cat <<EOF | sudo tee /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus Monitoring
After=network.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Aplica configurações do systemd e inicia Prometheus
sudo systemctl daemon-reload
sudo systemctl enable --now prometheus

# Instala Grafana
sudo apt install -y apt-transport-https software-properties-common wget
wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
sudo add-apt-repository "deb https://packages.grafana.com/oss/deb stable main"
sudo apt update && sudo apt install -y grafana

echo "Instalação finalizada. Acesse Grafana em http://<SEU_IP>:3000"
