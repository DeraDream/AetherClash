import 'package:fl_clash/common/app_ports.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/views/views.dart';
import 'package:material_ui/material_ui.dart';

class Navigation implements NavigationPort {
  static Navigation? _instance;

  @override
  List<NavigationItem> getItems({
    bool openLogs = false,
    bool hasProxies = false,
  }) {
    return [
      NavigationItem(
        keep: false,
        icon: const Icon(Icons.home_rounded),
        label: PageLabel.dashboard,
        builder: (_) =>
            const ControlCenterView(key: GlobalObjectKey(PageLabel.dashboard)),
        modes: const [NavigationItemMode.mobile, NavigationItemMode.laptop],
      ),
      NavigationItem(
        icon: const Icon(Icons.wifi_rounded),
        label: PageLabel.proxies,
        builder: (_) =>
            const ProxiesView(key: GlobalObjectKey(PageLabel.proxies)),
        modes: hasProxies ? NavigationItemMode.values : const [],
      ),
      NavigationItem(
        icon: const Icon(Icons.dns_rounded),
        label: PageLabel.profiles,
        builder: (_) =>
            const ProfilesView(key: GlobalObjectKey(PageLabel.profiles)),
      ),
      NavigationItem(
        icon: const Icon(Icons.lock_outline_rounded),
        label: PageLabel.po0,
        builder: (_) =>
            const Po0FirewallView(key: GlobalObjectKey(PageLabel.po0)),
      ),
      NavigationItem(
        icon: const Icon(Icons.memory_rounded),
        label: PageLabel.core,
        builder: (_) =>
            const CoreView(key: GlobalObjectKey(PageLabel.core)),
        modes: const [NavigationItemMode.laptop, NavigationItemMode.desktop],
      ),
      NavigationItem(
        icon: const Icon(Icons.rule_rounded),
        label: PageLabel.rules,
        builder: (_) =>
            const RoutingRulesView(key: GlobalObjectKey(PageLabel.rules)),
        modes: const [NavigationItemMode.laptop, NavigationItemMode.desktop],
      ),
      NavigationItem(
        icon: const Icon(Icons.storage_rounded),
        label: PageLabel.resources,
        builder: (_) =>
            const ResourcesView(key: GlobalObjectKey(PageLabel.resources)),
        modes: const [NavigationItemMode.laptop, NavigationItemMode.desktop],
      ),
      NavigationItem(
        icon: const Icon(Icons.public_rounded),
        label: PageLabel.activity,
        builder: (_) =>
            const ActivityView(key: GlobalObjectKey(PageLabel.activity)),
        modes: const [NavigationItemMode.laptop, NavigationItemMode.desktop],
      ),
      NavigationItem(
        icon: const Icon(Icons.settings_rounded),
        label: PageLabel.tools,
        builder: (_) => const ToolsView(key: GlobalObjectKey(PageLabel.tools)),
      ),
    ];
  }

  Navigation._internal();

  factory Navigation() {
    _instance ??= Navigation._internal();
    return _instance!;
  }
}

final navigation = Navigation();
