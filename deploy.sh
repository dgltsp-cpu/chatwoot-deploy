#!/usr/bin/env bash
# ============================================================
# Chatwoot 一键部署脚本（自托管社区版 + Docker Compose）
# 适用：Ubuntu 22.04/24.04、Debian 12（root 或 sudo）
#
# 用法：
#   1) 把整个 chatwoot-deploy 目录上传到 VPS，如 /root/chatwoot-deploy
#   2) cd chatwoot-deploy
#   3) cp .env.example .env
#   4) 编辑 .env，把 FRONTEND_URL 改成你的域名（必填）
#   5) sudo bash deploy.sh
# ============================================================
set -euo pipefail

cd "$(dirname "$0")"
echo "==> 工作目录：$(pwd)"

# ---------- 1. root / sudo 检查 ----------
if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  command -v sudo >/dev/null 2>&1 || { echo "错误：请以 root 运行（或先安装 sudo）"; exit 1; }
  SUDO="sudo"
  echo "==> 非 root 用户，后续使用 sudo"
fi

# ---------- 2. 安装 Docker + Compose 插件 ----------
if ! command -v docker >/dev/null 2>&1; then
  echo "==> 未检测到 Docker，开始安装（get.docker.com 官方脚本）..."
  curl -fsSL https://get.docker.com | $SUDO sh
  $SUDO systemctl enable --now docker || true
fi
echo "==> Docker: $(docker --version)"

if ! docker compose version >/dev/null 2>&1; then
  echo "==> 安装 Docker Compose 插件..."
  if command -v apt-get >/dev/null 2>&1; then
    $SUDO apt-get update -y && $SUDO apt-get install -y docker-compose-plugin
  elif command -v dnf >/dev/null 2>&1; then
    $SUDO dnf install -y docker-compose-plugin
  elif command -v yum >/dev/null 2>&1; then
    $SUDO yum install -y docker-compose-plugin || $SUDO yum install -y docker-compose
  else
    echo "错误：无法自动安装 compose 插件，请手动安装后重试"
    exit 1
  fi
fi
echo "==> Compose: $(docker compose version)"

# ---------- 3. .env 检查与密钥生成 ----------
if [ ! -f .env ]; then
  cp .env.example .env
  echo "==> 已生成 .env（模板）。请先编辑 FRONTEND_URL 为你的域名，然后重新执行本脚本。"
  echo "    当前值：$(grep '^FRONTEND_URL=' .env)"
  exit 1
fi

FRONTEND_URL=$(grep -E '^FRONTEND_URL=' .env | head -n1 | cut -d= -f2- || true)
case "$FRONTEND_URL" in
  "" | "http://0.0.0.0:3000" | *example.com*)
    echo "错误：.env 中的 FRONTEND_URL 仍是占位符（当前：$FRONTEND_URL）"
    echo "请改为真实域名，例如：FRONTEND_URL=https://chat.yourdomain.com"
    exit 1 ;;
esac

# 为空则自动生成随机密钥（openssl rand -hex N，只改“= 后为空”的行）
gen_if_empty() {
  local key="$1" len="${2:-64}"
  if grep -qE "^${key}=$" .env; then
    sed -i "s/^${key}=$/${key}=$(openssl rand -hex "$len")/" .env
    echo "==> 已生成 $key"
  fi
}
gen_if_empty SECRET_KEY_BASE 64
gen_if_empty POSTGRES_PASSWORD 32
gen_if_empty REDIS_PASSWORD 32

# ---------- 4. 启动 ----------
echo "==> 拉取镜像并启动（首次约 5~10 分钟，取决于网络）..."
docker compose up -d
sleep 10
echo "==> 容器状态："
docker compose ps

# ---------- 5. 初始化数据库（首次部署必须） ----------
echo "==> 初始化数据库（rails db:chatwoot_prepare）..."
ok=0
for i in 1 2 3; do
  if docker compose run --rm rails bundle exec rails db:chatwoot_prepare; then
    ok=1
    break
  fi
  echo "  第 ${i} 次失败，10 秒后重试..."; sleep 10
done
[ "$ok" = "1" ] || { echo "错误：数据库初始化失败，请查看上方日志"; exit 1; }

# ---------- 6. 完成 ----------
echo ""
echo "=========================================================="
echo " 部署完成！"
echo " 服务端本机检查：curl -s http://127.0.0.1:3000 | head"
echo ""
echo " 下一步："
echo "  1) 域名 DNS 解析到本机 IP（A 记录）"
echo "  2) 配置 HTTPS 反向代理到 http://127.0.0.1:3000"
echo "     - 宝塔：见同目录《部署方案.md》第四节"
echo "     - Nginx：见 nginx-chatwoot.conf.example"
echo "  3) 打开 https://${FRONTEND_URL#https://} 注册管理员账号"
echo "     官方注册路径：/app/auth/signup"
echo "=========================================================="
