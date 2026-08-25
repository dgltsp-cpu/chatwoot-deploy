# Chatwoot 自托管部署（自定义镜像版，Docker Compose）

基于自定义镜像 `ghcr.io/dgltsp-cpu/chatwoot:v4.17.1-custom` 的生产环境部署仓库。
镜像由 [dgltsp-cpu/chatwoot-v4](https://github.com/dgltsp-cpu/chatwoot-v4) 源码构建，
**VPS 上只需要本仓库，不需要克隆源码仓库**。

镜像已固化以下修改：

- ActiveStorage 附件走 proxy 路由（手机 App 图片能显示）
- 签名 URL 有效期 365 天（App 不再 404）
- 图片/视频一律 `Content-Disposition: inline`（不再变成“只能下载”）
- widget 图片灯箱（全屏预览、多图滑动、关闭键、无下载键）
- 新账号默认隐藏“由 Chatwoot 支持”

本仓库含：

- `docker-compose.production.yaml` — Rails / Sidekiq / PostgreSQL(pgvector) / Redis
- `deploy.sh` — 一键部署：安装 Docker、生成密钥、启动容器、初始化数据库
- `backup.sh` — 备份 PostgreSQL 与上传文件，保留最近 7 天
- `nginx-chatwoot.conf.example` — Nginx / 宝塔反代配置示例
- `部署方案.md` — 详细部署文档

## 快速部署

```bash
git clone https://github.com/dgltsp-cpu/chatwoot-deploy.git
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

新账号默认已隐藏（镜像内 `disable_branding` 默认开启）。
老账号（升级前注册的）执行一次：

```bash
docker compose -f docker-compose.production.yaml exec rails bundle exec rails runner "Account.first.enable_features!('disable_branding')"
```

详细步骤见 [部署方案.md 第十二节](部署方案.md)。

## 修复：App 里图片显示不了（网页正常、App 空白）

以下修复已固化进自定义镜像，不再需要挂载文件：

1. **302 跳转**：Chatwoot 默认图片地址是 `/rails/active_storage/.../redirect/...`，
   返回 302 再跳到真实文件。手机 App 不跟随 302，所以图片加载空白；浏览器会自动跟随所以正常。
   已改为 proxy 方式：Rails 直接返回图片内容（200、无跳转）。
2. **地址过期**：签名地址 Rails 默认 5 分钟过期，App 缓存旧地址后加载 404。已延长到一年。
3. **视频播不了（App）**：Chatwoot 官方只把 audio 加进了"允许内联播放"名单，漏了 video，
   视频被标记为 `Content-Disposition: attachment`，iOS 自带播放器（AVPlayer）会拒绝播放
   （网页浏览器忽略该头所以正常）。已把常见视频格式（mp4/mov/webm 等）加入内联名单。

## 从 v4.16.2 官方版升级到自定义镜像

```bash
cd ~/chatwoot-deploy
git pull
# docker-compose.production.yaml 已改为自定义镜像，并移除了挂载行
docker compose -f docker-compose.production.yaml pull
docker compose -f docker-compose.production.yaml up -d
docker compose -f docker-compose.production.yaml exec rails bundle exec rails db:migrate
docker compose -f docker-compose.production.yaml restart rails sidekiq
# 老账号去掉品牌（新账号默认已隐藏）
docker compose -f docker-compose.production.yaml exec rails bundle exec rails runner 'Account.find_each { |a| a.enable_features!(:disable_branding) }'
```

部署/升级后执行：

```bash
docker compose -f docker-compose.production.yaml up -d
docker compose -f docker-compose.production.yaml restart rails
```

验证是否生效：

```bash
docker compose -f docker-compose.production.yaml exec rails bundle exec rails runner \
  'a = Attachment.last; puts a.file_url; puts Rails.application.config.active_storage.resolve_model_to_route'
```

看到 `/rails/active_storage/blobs/proxy/...` 和 `rails_storage_proxy` 即生效。
然后在手机 App 里下拉刷新会话；旧消息刷新后会拿到新地址并正常显示。
