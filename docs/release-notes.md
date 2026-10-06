AetherClash v5.5.16：修正规则页职责与规则覆盖逻辑，并完成规则开关 / 外部资源更新专项验证。

## 规则页修正

- 删除规则页顶部多余的“规则 / 全局 / 直连”模式切换
- 左侧顶部模式切换继续只负责 Mihomo 运行模式
- 一级“规则”页面只负责：
  - 展示当前运行配置中的规则
  - 显示真实命中 / 未命中统计
  - 显示命中百分比
  - 搜索规则
  - 启用 / 禁用单条规则
- 规则页开关作为 AetherClash 持久化覆盖层，不修改原订阅 / 原配置文件
- 用户禁用的规则在配置重新加载、订阅更新、Core 重启后会自动重新应用
- 规则覆盖层优先于配置文件本身的启用状态

## 规则开关验证

已对 Mihomo Runtime RuleWrapper 做专项验证：

- 禁用后规则真实停止匹配
- 重新启用后规则恢复匹配
- 运行时 disabled 状态可正确回读
- 越界规则索引不会错误生效
- 配置重新加载后会从本地数据库重新应用禁用覆盖状态

## 外部资源验证

### Rule Provider

- 单项“刷新”会实际调用当前 Provider 的 Update()
- 更新成功后重新读取 Provider 状态
- “更新全部”使用同一真实更新路径
- HTTP / FILE / INLINE 等 Provider 按 Mihomo 当前能力处理
- Provider 内容编辑 / 只读逻辑保持不变：
  - HTTP：可编辑本地缓存，远程更新会覆盖
  - FILE：可编辑本地文件
  - INLINE：只读
  - MRS：解析后只读

### Geo 数据

- MMDB / ASN / GEOIP / GEOSITE 的手动更新会真实进入 Mihomo updater
- 更新中的状态继续由 Core 事件驱动
- 更新完成 / 跳过 / 失败会正确结束 loading 状态并反馈结果

## 同时包含 v5.5.15 功能

- 桌面端移除顶部代理总开关
- Mihomo Core 桌面端自动运行
- 运行时间移动至左下角 IP 下方
- 系统代理 / TUN 保持独立
- 修复重复 push 网络设置页面
- 新增一级“规则”页面
- 新增一级“外部资源”页面
- 设置中的旧“资源”入口移除
- GeoData DB / DAT 与 Loader 配置
- Rule Provider 搜索、单项刷新、更新全部、查看 / 编辑
- Inline / MRS 内容查看
- Mihomo RuleWrapper 真实统计接口

## 验证

发布前已通过：

- Flutter Analyze
- 规则 / 资源相关 Dart Tests
- Mihomo Core 规则开关专项 Go Test
- Rule Provider 更新专项 Go Test
- Geo updater 专项 Go Test
- Go Core Tests
- Go Vet
- Windows / macOS 正式打包流程

## 发布目标

- Windows amd64 Setup EXE
- Windows amd64 ZIP
- macOS arm64 DMG

Android 与 macOS Intel 继续保持停用。
