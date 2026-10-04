AetherClash v5.5.5：重构桌面代理接管、网络拓扑与网络诊断，并新增运行时配置和流量嗅探。

## 本次更新

- 重构桌面「系统代理 / 虚拟网卡」控制
  - 移除原有 Tab / 二选一样式
  - 改为两个独立卡片，各自拥有独立开关
  - 系统代理与 TUN 允许独立开启或关闭
  - TUN 开启增加二次确认
  - TUN 授权失败只关闭 TUN，不再自动切换系统代理
- 重做「网络拓扑」
  - 参考 Clash Party 的实时连接拓扑
  - 基于 mihomo Connections 动态生成代理组 → 节点 → 规则 → 来源 IP → 来源端口
  - 显示连接数和流量，并支持展开、折叠、拖动与缩放
  - 支持暂停 / 恢复实时刷新
- 完善「网络信息」
  - 当前公网 IP 支持多数据源切换和手动刷新
  - 增加国家 / 地区、城市、ASN、运营商 / 组织及数据来源
  - 延迟检测目标支持新增、删除和编辑，并持久保存
  - 默认保留 Google、Cloudflare、GitHub
- 新增「运行时配置」
  - 从内核页面进入
  - 查看最终生成并交给 mihomo 的 YAML
  - 支持 YAML 高亮、搜索、刷新、复制全部和导出
  - TUN 状态按照实际授权状态生成
- 新增「流量嗅探」
  - 独立 Sniffer 设置页面
  - 支持 HTTP / TLS / QUIC 端口配置
  - 支持覆盖目标地址、Force DNS Mapping、Parse Pure IP
  - 支持强制嗅探域名、跳过域名、跳过来源 / 目标 IP 或 CIDR
  - 修改后自动重新生成 mihomo 配置并持久保存
- 网络信息页继续保持在桌面工作区内打开，左侧主菜单始终可见
- Release 继续只构建 Windows amd64 与 macOS arm64
- 修复本轮发布前检查发现的问题
  - 修复网络信息页缺少枚举导入导致的 FontFamily / MessageLevel 编译失败
  - 修复桌面系统代理 / 虚拟网卡卡片在部分尺寸下纵向溢出
  - 更新独立 TUN 行为对应的测试
  - 更新 AetherClash User-Agent 测试与请求页暂停 / 恢复图标测试
  - Release 增加 Preflight：Analyze 与测试通过后才进入 Windows / macOS 正式打包

## 桌面在线升级

Windows 用户可从应用内直接检查更新。下载并安装完成后，AetherClash 会自动重新启动。

## 发布目标

- Windows amd64
- macOS arm64

Android 与 macOS Intel 仍暂时停用，相关构建代码未删除。
