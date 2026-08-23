# Chatwoot 移动 App 图片显示修复（症状：网页/客服后台能显示，手机 App 显示不了）
#
# 1) Chatwoot 默认生成的图片地址是 302 跳转链接（/rails/active_storage/.../redirect/...），
#    手机 App（iOS/Android）不跟随 302，所以图片加载不出来；浏览器会自动跟随所以正常。
#    改成 proxy 后，Rails 直接把图片内容返回（200、无跳转），App 即可正常显示。
# 2) Rails 签名地址默认 5 分钟过期，App 缓存旧地址后加载会 404，这里延长到一年。
Rails.application.config.active_storage.resolve_model_to_route = :rails_storage_proxy
Rails.application.config.active_storage.service_urls_expire_in = 365.days
