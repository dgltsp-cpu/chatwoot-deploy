# Chatwoot 自托管一键部署（Docker Compose）

基于官方 `chatwoot/chatwoot` 镜像的生产环境部署方案，含：

- `docker-compose.production.yaml` — Rails / Sidekiq / PostgreSQL(pgvector) / Redis
- `deploy.sh` — 一键部署：安装 Docker、生成密钥、启动容器、初始化数据库
- `backup.sh` — 备份 PostgreSQL 与上传文件，保留最近 7 天
- `nginx-chatwoot.conf.example` — Nginx / 宝塔反代配置示例
- `部署方案.md` — 详细部署文档

## 快速部署

```bash
git clone https://github.com/<你的用户名>/chatwoot-deploy.git
cd chatwoot-deploy
cp .env.example .env
# 编辑 .env，把 FRONTEND_URL 改为你的真实域名（必填）
sudo bash deploy.sh
```

> 首次部署约 5~10 分钟。完成后配置 HTTPS 反向代理到 `http://127.0.0.1:3000`，
> 再打开 `https://你的域名/app/auth/signup` 注册管理员账号。

## 安全说明

- `.env` 已被 `.gitignore` 忽略，密钥由 `deploy.sh` 自动生成，不会进入 git。
- 注册完管理员后，建议把 `.env` 中 `ENABLE_ACCOUNT_SIGNUP` 改为 `false` 并重启容器。

## 隐藏「由 Chatwoot 支持」水印

组件底部水印由账户功能 `disable_branding` 控制，社区版后台无开关，用 `rails runner` 开启：

```bash
docker compose -f docker-compose.production.yaml exec rails bundle exec rails runner "Account.first.enable_features!('disable_branding')"
```

详细步骤见 [部署方案.md 第十二节](部署方案.md)。
