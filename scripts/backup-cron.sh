#!/usr/bin/env bash
set -e

# Создаём каталог для дампов
mkdir -p /backups

# Записываем cron задачу
cat <<EOF > /etc/cron.d/db-backup
${CRON_SCHEDULE} root PGPASSWORD=${POSTGRES_PASSWORD} pg_dumpall -U ${POSTGRES_USER} -h postgres > /backups/\$(date +\%\%Y-\%\%m-\%\%d).sql && \
cd /backups
EOF

chmod 0644 /etc/cron.d/db-backup
service cron reload
tail -f /var/log/cron.log
# Запускаем cron в форграунд режиме
# exec crond -f -l 2
