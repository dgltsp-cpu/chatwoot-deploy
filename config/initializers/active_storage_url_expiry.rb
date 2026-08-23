# Chatwoot 移动 App 附件显示/播放修复（症状：网页/客服后台正常，手机 App 显示或播放不了）
#
# 1) Chatwoot 默认生成的图片地址是 302 跳转链接（/rails/active_storage/.../redirect/...），
#    手机 App（iOS/Android）不跟随 302，所以图片加载不出来；浏览器会自动跟随所以正常。
#    改成 proxy 后，Rails 直接把文件内容返回（200、无跳转），App 即可正常显示。
# 2) Rails 签名地址默认 5 分钟过期，App 缓存旧地址后加载会 404，这里延长到一年。
# 3) 视频被标记为 Content-Disposition: attachment（当作附件下载），iOS 自带播放器
#    （AVPlayer）会拒绝播放，表现为"刚发能播、过会儿只能下载"；浏览器忽略该头所以正常。
#    注意：必须直接修改 ActiveStorage.content_types_allowed_inline 这个模块变量，
#    改 config.active_storage.content_types_allowed_inline 无效 —— 引擎在应用初始化
#    前就把它复制走了，且用 += 会生成新数组，模块变量仍是旧列表。
Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy
Rails.application.config.active_storage.service_urls_expire_in = 365.days

ActiveStorage.content_types_allowed_inline.concat(%w[
  video/mp4
  video/quicktime
  video/x-m4v
  video/webm
  video/ogg
  video/x-matroska
])
