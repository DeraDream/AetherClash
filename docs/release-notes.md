AetherClash v5.5.15：重构桌面端代理控制逻辑，并新增“规则”和“外部资源”两个一级功能页面。

## 桌面端代理控制

- 移除桌面侧栏顶部额外的“代理总开关”
- Mihomo Core 在桌面端按应用生命周期自动运行，不再要求用户手动开启总开关
- 用户侧仅保留两个主要入口：
  - 系统代理
  - 虚拟网卡 / TUN
- 原总开关下方的运行时间移动到左下角 IP 信息下方
- 修复系统代理 / 虚拟网卡卡片连续点击时重复 push 网络设置页面的问题
- 系统代理和 TUN 卡片仍保持“点卡片进入网络设置、点 Switch 只切换状态”的独立交互

## 规则

新增左侧一级“规则”页面，规则直接来自当前 Mihomo 运行配置。

- 支持按规则类型、内容、策略搜索
- 直接读取 Mihomo RuleWrapper 的真实运行时统计，不使用客户端估算
- 显示：
  - 命中次数
  - 总匹配次数
  - 命中百分比
  - 最近命中 / 匹配时间
- 每条规则支持运行时启用 / 禁用
- 规则开关直接控制 Mihomo Runtime RuleWrapper，不改写订阅原文件
- 配置 / Core 重新加载后自动重新读取当前规则状态
- 页面定时刷新统计数据，无需手动刷新才能看到命中变化

## 外部资源

将原“设置 → 资源”迁移为左侧一级“外部资源”页面，设置中不再保留重复入口。

### Geo 数据

保留并扩展现有资源管理：

- GeoIP
- GeoSite
- MMDB
- ASN
- 自动更新
- 更新间隔
- 单项刷新
- 文件信息

新增：

- GeoData 数据模式：DB / DAT
- GeoData Loader：Memconservative / Standard
- 相关设置持久化并应用到实际运行配置

### Rule Providers

从当前配置的 rule-providers 实时读取规则集合。

- 支持搜索 Provider
- 显示 Provider 名称、来源类型、Behavior、Format、规则数量、更新时间
- 支持单项刷新
- 支持更新全部
- 配置切换后自动刷新当前 Provider 列表
- Core 尚未初始化或没有当前配置时不会错误发起 Provider IPC

## 规则集查看 / 编辑

每个 Rule Provider 右侧提供：

- 查看 / 编辑
- 刷新

按 Provider 类型和格式分别处理：

- HTTP：可编辑本地缓存，明确提示下次远程更新会覆盖修改
- FILE：可编辑本地文件
- INLINE：只读查看，修改应回到当前配置文件
- MRS：由 Core 解析为文本后只读查看，不直接修改二进制文件

编辑器复用 AetherClash 现有编辑器能力，不额外引入第二套文本编辑组件。

## Mihomo Core 接口

为上述功能补充桌面 Core Bridge：

- getRules
- setRuleDisabled
- getExternalProviderContent
- RuleWrapper 命中 / 未命中统计
- Inline Rule Provider 资源暴露
- MRS 规则集文本解析

## UI 重构

本版本同时包含此前确认的桌面 UI 重构：

- 配置创建改为桌面弹窗
- 设置页、配置页、工具页进一步扁平化
- 对话框改为更接近 macOS 的简洁样式
- 删除免责声明启动流程
- 左侧主导航在桌面子页面中保持常驻

## 验证

发布前完成：

- Dart Format：通过
- Flutter Analyze：通过
- 规则 / 资源专项 Dart Tests：通过
- 主分支完整 Flutter Tests：通过
- Go gofmt：通过
- Go Core Tests：通过
- Go vet：通过
- Runtime RuleWrapper 命中统计 / 开关专项测试：通过
- Inline Rule Provider 列表 / 内容专项测试：通过
- Rule Provider 资源页专项测试：通过
- 主分支正式 Preflight：通过

## 发布目标

- Windows amd64 Setup EXE
- Windows amd64 ZIP
- macOS arm64 DMG

Android 与 macOS Intel 继续保持停用。
