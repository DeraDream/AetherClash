AetherClash v5.5.13：升级 Mihomo Core 到 v1.19.32，并补齐 FlClash 已验证的 MIPS / EasyTier / 新协议兼容适配，同时继续优化桌面端发布流水线。

## Core 升级

- Mihomo Core 升级到 v1.19.32
- 使用 FlClash 已适配的 Core 提交：
  `8597778c7df410ebe88c57e59eaab32d203156df`
- 同步更新 `core/go.mod` / `core/go.sum`
- 自动获得 v1.19.32 内核包含的协议修复、依赖升级、性能和稳定性优化

## TUN / MIPS

- 新增 `TunStack.mips`
- 新配置默认使用 MIPS TUN stack
- TUN Stack 设置页自动提供 `mips` 选项
- Core 无法识别 stack 时默认回退到 `TunMips`
- 补充 MIPS 默认值和 JSON round-trip 回归测试

## EasyTier / Core API

- 补齐 EasyTier 节点类型兼容
- 新增逐节点 `validateProxies` Core API
- EasyTier / Tailscale 校验时使用临时名称，避免探测关闭时误删除正在运行的同名 DNS client
- 更新 Proxies Core wrapper，减少无用 history 序列化并保持现有代理组数据兼容
- 增加 `validateProxies` Go 回归测试

## 新协议兼容

随新版 Core 获得并确认支持：

- XHTTP transport / `xhttp-opts`
- REALITY `support-x25519mlkem768`
- EasyTier outbound
- 新版 mipstack / gVisor / sing-tun 等依赖

当前 AetherClash 仍使用现有编辑器，因此这些配置可以在 YAML 中正常使用，但暂不迁移新版 FlClash 的 Schema 自动补全 UI。

## 发布流水线优化

- Native Core / Helper cache 仅接受精确命中，避免恢复无效旧缓存
- macOS 缓存固定版本 appdmg
- Release Package 默认关闭 Flutter verbose 日志
- 保留手动 verbose 开关用于故障诊断
- Windows Pub cache 经 A/B 验证后继续保留

## 发布前验证

- Dart Format：通过
- Flutter Analyze：通过
- 完整 Flutter Tests：通过
- Go Core wrapper：通过
- Android Core NDK / cgo 验证：通过
- Rust tests：通过
- Plugins：通过
- Android unit tests：通过
- Windows amd64 实际打包验证：通过
- macOS arm64 实际打包验证：通过

## 发布目标

- Windows amd64 Setup EXE
- Windows amd64 ZIP
- macOS arm64 DMG

Android 与 macOS Intel 继续暂时停用，相关构建代码仍保留。
