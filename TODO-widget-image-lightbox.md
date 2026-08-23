# TODO：访客端聊天图片灯箱（待做，先不改代码）

## 需求（2026-08-23 记录）
- 位置：`chatwoot-src/app/javascript/widget/components/ImageBubble.vue`
- 现状：访客端 widget 图片只是 `<a href="原图" target="_blank">`，点击新标签打开，无灯箱
- 目标：点击图片弹出灯箱（全屏遮罩预览原图）
  - 同一消息/会话多张图片支持**左右切换**（箭头按钮 + 键盘 ←/→），显示张数（如 2/5）
  - **要加：关闭按键**
  - **不需要：下载按键**

## 参考实现
- 客服端已有现成灯箱：`dashboard/components/widgets/conversation/components/GalleryView.vue`
  （左右箭头 + 键盘 ArrowLeft/ArrowRight + 底部张数 + 缩放/旋转/下载/关闭）
  - 可参考其交互，访客端按需精简（去掉下载/缩放/旋转，保留关闭 + 左右切换 + 张数）

## 待办
- [ ] 改 `ImageBubble.vue`：点击弹灯箱、左右切换、关闭按键、张数
- [ ] 重新构建 Chatwoot 镜像并部署（chatwoot-deploy 那套）
- [ ] 验证访客端效果
