#!/bin/bash
set -e

LOKI_VERSION=$(curl -s https://api.github.com/repos/grafana/loki/releases/latest | grep tag_name | cut -d '"' -f 4)
echo "Instalando Loki $LOKI_VERSION"

# Download
cd /usr/local/bin
curl -LO "https://github.com/grafana/loki/releases/download/${LOKI_VERSION}/loki-linux-amd64.zip"
unzip loki-linux-amd64.zip
mv loki-linux-amd64 loki
chmod +x loki
rm loki-linux-amd64.zip

# Configuração
mkdir -p /etc/loki /var/lib/loki /var/log/loki
cat <<EOF > /etc/loki/loki-config.yaml
auth_enabled: false

server:
  http_listen_port: 3100

ingester:
  lifecycler:
    ring:
      kvstore:
        store: inmemory
      replication_factor: 1
  chunk_idle_period: 5m
  max_chunk_age: 1h

schema_config:
  configs:
    - from: 2022-01-01
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

storage_config:
  boltdb_shipper:
    active_index_directory: /var/lib/loki/index
    cache_location: /var/lib/loki/boltdb-cache
    shared_store: filesystem
  filesystem:
    directory: /var/lib/loki/chunks

limits_config:
  enforce_metric_name: false
  reject_old_samples: true
  reject_old_samples_max_age: 168h

table_manager:
  retention_deletes_enabled: true
  retention_period: 168h
EOF

# systemd unit
cat <<EOF > /etc/systemd/system/loki.service
[Unit]
Description=Grafana Loki
After=network.target

[Service]
ExecStart=/usr/local/bin/loki -config.file=/etc/loki/loki-config.yaml
Restart=always
User=root
Group=root
LimitNOFILE=65536
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=loki

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now loki

echo "✅ Loki instalado e rodando via systemd"
