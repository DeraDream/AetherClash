import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connection/connections.dart';
import 'logs.dart';

/// Live traffic in one place. Connection history is folded into the
/// connections page (active/closed) following Clash Party's model.
class ActivityView extends ConsumerStatefulWidget {
  const ActivityView({super.key});

  @override
  ConsumerState<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends ConsumerState<ActivityView> {
  PageLabel _current = PageLabel.connections;

  @override
  Widget build(BuildContext context) {
    final openLogs = ref.watch(
      appSettingProvider.select((state) => state.openLogs),
    );
    final tabs = [
      PageLabel.connections,
      if (openLogs) PageLabel.logs,
    ];
    final current = tabs.contains(_current) ? _current : tabs.first;
    return ScaffoldTitleSlot(
      title: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: GlassSegmented<PageLabel>(
          height: 40,
          values: tabs,
          selected: current,
          labelOf: (label) => label.label,
          onChanged: (label) => setState(() => _current = label),
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(current),
        child: switch (current) {
          PageLabel.logs => const LogsView(),
          _ => const ConnectionsView(),
        },
      ),
    );
  }
}
