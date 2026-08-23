# 延长 ActiveStorage 签名图片 URL 的有效期（Rails 默认只有 5 分钟）
# 问题：iOS/Android App 会缓存消息里的图片地址，超过有效期后加载返回 404，
#       所以 App 里显示不了旧消息的图片；网页端每次重新拉取消息所以正常。
# 解决：把有效期改为一年。改完后需要重启容器，并让 App 里下拉刷新会话。
Rails.application.config.active_storage.service_urls_expire_in = 365.days
