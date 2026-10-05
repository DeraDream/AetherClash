AetherClash v5.5.12：修复流量嗅探配置序列化导致 Core 配置加载失败的问题，并优化发布打包流程。

## 关键修复

- 修复流量嗅探开启后出现：
  `NoSuchMethodError: Class '_SnifferConfig' has no instance method '[]'`
- HTTP / TLS / QUIC 嗅探协议配置在写入 Mihomo YAML 前统一转换为纯 Map
- 修复嗅探配置保存与重新读取的嵌套序列化
- 避免配置生成失败后连带导致：
  - Core 无法加载配置
  - 策略组为空
  - 左侧“代理”入口消失
  - 系统代理 / TUN 无法正常工作
- 增加 Sniffer 原始配置转换及持久化 round-trip 回归测试

## 构建流程优化

- release 元数据提交可安全复用直接父提交已经通过的 Preflight
- 仅当发布提交只修改版本号与 release notes 时才复用；其他变化自动完整重测
- Brand assets 与 Preflight 并行
- 图标生成任务不再安装不需要的 Flutter SDK
- Brand assets 增加内容哈希缓存
- Go Core / Rust Helper 增加跨 GitHub Actions Run 的原生产物缓存
- 原有 Core fingerprint、输出校验和 Helper/Core SHA-256 绑定继续保留
- Windows amd64 / macOS arm64 仍并行构建，产物格式不变

## 发布前验证

- Dart Format / Parse：通过
- Flutter Analyze：通过
- 完整 Flutter Tests：通过
- Sniffer 嵌套协议纯 Map 回归：通过
- Sniffer 配置保存 / 读取 round-trip：通过
- 优化后的普通 Preflight workflow：通过

## 发布目标

- Windows amd64
- macOS arm64

Android 与 macOS Intel 继续暂时停用，相关构建代码仍保留。
