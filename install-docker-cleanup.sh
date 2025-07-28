#!/bin/bash

set -euo pipefail

SCHEDULE="${1:-}"

if [[ -z "$SCHEDULE" ]]; then
  echo "Uso: $0 \"<OnCalendar expression>\""
  echo "Exemplos:"
  echo "  $0 \"Sun *-*-* 03:00:00\"     # todo domingo às 03h"
  echo "  $0 \"daily\"                  # todo dia à meia-noite"
  exit 1
fi

echo "Instalando script de limpeza profunda em /usr/local/bin/docker-deep-clean.sh..."
cat << 'EOF' > /usr/local/bin/docker-deep-clean.sh
#!/bin/bash
set -euo pipefail

echo "Iniciando limpeza profunda do Docker..."

before=$(df -h /var/lib/docker | tail -1 | awk '{print $4}')
echo "Espaço livre antes da limpeza: $before"

echo "Executando: docker system prune -af --volumes"
docker system prune -af --volumes

echo "Executando: docker builder prune -af"
docker builder prune -af

echo "Zerando arquivos de log em /var/lib/docker/containers..."
find /var/lib/docker/containers/ -name "*.log" -type f -exec truncate -s 0 {} \;

after=$(df -h /var/lib/docker | tail -1 | awk '{print $4}')
echo "Limpeza concluída!"
echo "Espaço livre depois da limpeza: $after"
EOF

chmod +x /usr/local/bin/docker-deep-clean.sh

echo "Criando serviço systemd..."
cat << EOF > /etc/systemd/system/docker-deep-clean.service
[Unit]
Description=Deep Docker Cleanup
Wants=docker.service
After=docker.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/docker-deep-clean.sh
EOF

echo "Criando timer systemd com agendamento: $SCHEDULE"
cat << EOF > /etc/systemd/system/docker-deep-clean.timer
[Unit]
Description=Run Deep Docker Cleanup ($SCHEDULE)

[Timer]
OnCalendar=$SCHEDULE
Persistent=true

[Install]
WantedBy=timers.target
EOF

echo "Recarregando systemd e ativando timer..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable --now docker-deep-clean.timer

echo "Timer de limpeza profunda agendado com sucesso!"
echo "Agendamento: $SCHEDULE"
echo "Verifique com: systemctl list-timers | grep docker-deep-clean"