# Chatwoot 移动 App 附件显示/播放修复（症状：网页/客服后台正常，手机 App 显示或播放不了）
#
# 1) 302 跳转：默认图片地址是 /rails/active_storage/.../redirect/...（302），
#    手机 App 不跟随 302，图片加载不出来；浏览器自动跟随所以正常。
#    改为 proxy 后 Rails 直接返回内容（200、无跳转）。
# 2) 签名地址默认 5 分钟过期，App 缓存旧地址后加载 404，这里延长到一年。
# 3) 视频被标记为 Content-Disposition: attachment，iOS 自带播放器（AVPlayer）
#    会拒绝播放，表现为"刚发能播、过会儿只能下载"；浏览器忽略该头所以正常。
#    只改 config 里的允许列表不一定生效（Rails 启动后期才把 config 复制到
#    ActiveStorage 模块变量，时序不确定），所以最稳的办法是在 Rails 启动
#    最后阶段（after_initialize）给 ActiveStorage::Blob 打补丁：
#    video/* 一律不强制为附件。
Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy
Rails.application.config.active_storage.service_urls_expire_in = 365.days

Rails.application.config.active_storage.content_types_allowed_inline += %w[
  video/mp4
  video/quicktime
  video/x-m4v
  video/webm
  video/ogg
  video/x-matroska
]

Rails.application.config.after_initialize do
  ActiveStorage::Blob.prepend(Module.new do
    def forced_disposition_for_serving
      return :attachment if forcibly_serve_as_binary?
      return nil if content_type.to_s.start_with?("video/")
      super
    end
  end)
end
