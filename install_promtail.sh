#!/bin/bash
set -e

PROMTAIL_VERSION=$(curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep tag_name | cut -d '"' -f 4)
echo "Instalando Promtail $PROMTAIL_VERSION"

# Download
cd /usr/local/bin
curl -LO "https://github.com/grafana/loki/releases/download/${PROMTAIL_VERSION}/promtail-linux-amd64.zip"
unzip promtail-linux-amd64.zip
mv promtail-linux-amd64 promtail
chmod +x promtail
rm promtail-linux-amd64.zip

# Config
mkdir -p /etc/promtail /var/log/promtail
cat <<EOF > /etc/promtail/promtail-config.yaml
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /var/lib/promtail/positions.yaml

clients:
  - url: http://<IP_DO_LOKI>:3100/loki/api/v1/push

scrape_configs:
  - job_name: robos-ftp-logs
    static_configs:
      - targets:
          - localhost
        labels:
          job: robos-ftp
          __path__: /opt/robos-ftp/logs/*.log
EOF

# Substitua <IP_DO_LOKI> pelo IP real ou DNS do servidor Loki

mkdir -p /var/lib/promtail

# systemd
cat <<EOF > /etc/systemd/system/promtail.service
[Unit]
Description=Grafana Promtail
After=network.target

[Service]
ExecStart=/usr/local/bin/promtail -config.file=/etc/promtail/promtail-config.yaml
Restart=always
User=root
Group=root
LimitNOFILE=65536
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=promtail

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now promtail

echo "✅ Promtail instalado e enviando logs via systemd"
