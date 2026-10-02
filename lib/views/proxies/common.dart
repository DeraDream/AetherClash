import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

double get listHeaderHeight {
  final measure = globalState.measure;
  return 20 + measure.titleMediumHeight + 4 + measure.bodyMediumHeight + 2;
}

double getItemHeight(ProxyCardType proxyCardType, {bool compact = false}) {
  final measure = globalState.measure;
  final nameLines = compact ? 1 : 2;
  final baseHeight =
      (compact ? 12 : 16) +
      measure.bodyMediumHeight * nameLines +
      measure.bodySmallHeight +
      (compact ? 6 : 8) +
      4;
  return switch (proxyCardType) {
    ProxyCardType.expand =>
      baseHeight + measure.labelSmallHeight + (compact ? 4 : 6),
    ProxyCardType.shrink => baseHeight,
    ProxyCardType.min => baseHeight - measure.bodyMediumHeight,
  };
}

class GroupOffsets {
  const GroupOffsets(this.groups, this.offsets);

  static const empty = GroupOffsets(<Group>[], <double>[]);

  final List<Group> groups;
  final List<double> offsets;

  bool get isEmpty => offsets.isEmpty;

  double offsetOf(String groupName) {
    final index = groups.indexWhere((group) => group.name == groupName);
    if (index < 0 || index >= offsets.length) {
      return 0;
    }
    return offsets[index];
  }

  Group? groupOf(String groupName) => groups.getGroup(groupName);
}

double getScrollToSelectedOffset({
  required WidgetRef ref,
  required String groupName,
  required List<Proxy> proxies,
  required int columns,
  bool compact = false,
}) {
  final proxyCardType = ref.read(
    proxiesStyleSettingProvider.select((state) => state.cardType),
  );
  final selectedProxyName = ref.read(selectedProxyNameProvider(groupName));
  final findSelectedIndex = proxies.indexWhere(
    (proxy) => proxy.name == selectedProxyName,
  );
  final selectedIndex = findSelectedIndex != -1 ? findSelectedIndex : 0;
  final rows = (selectedIndex / columns).floor();
  final spacing = compact ? 6.0 : 8.0;
  return rows * getItemHeight(proxyCardType, compact: compact) +
      (rows - 1) * spacing;
}
