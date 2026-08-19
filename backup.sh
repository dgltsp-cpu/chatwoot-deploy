#!/usr/bin/env bash
# ============================================================
# Chatwoot 备份脚本：PostgreSQL + 上传文件(storage)
# 用法：cd chatwoot-deploy && sudo bash backup.sh
# 备份输出到 ./backups/，自动保留最近 7 天
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p backups
TS=$(date +%Y%m%d_%H%M%S)

echo "==> [1/2] 备份 PostgreSQL..."
docker compose exec -T postgres pg_dump -U postgres -d chatwoot_production \
  | gzip > "backups/db_${TS}.sql.gz"
echo "    完成：backups/db_${TS}.sql.gz ($(du -h backups/db_${TS}.sql.gz | cut -f1))"

echo "==> [2/2] 备份上传文件(storage 卷)..."
RAILS_CID=$(docker compose ps -q rails)
STORAGE_SRC=$(docker inspect -f '{{range .Mounts}}{{if eq .Destination "/app/storage"}}{{.Source}}{{end}}{{end}}' "$RAILS_CID" | head -n1)
if [ -n "$STORAGE_SRC" ] && [ -d "$STORAGE_SRC" ]; then
  tar -czf "backups/storage_${TS}.tar.gz" -C "$STORAGE_SRC" .
  echo "    完成：backups/storage_${TS}.tar.gz ($(du -h backups/storage_${TS}.tar.gz | cut -f1))"
else
  echo "    (未找到 storage 卷挂载，跳过。)"
fi

echo "==> 清理 7 天前的备份..."
find backups -name 'db_*.sql.gz'    -mtime +7 -delete
find backups -name 'storage_*.tar.gz' -mtime +7 -delete

echo "==> 备份完成，当前备份列表："
ls -lh backups/
