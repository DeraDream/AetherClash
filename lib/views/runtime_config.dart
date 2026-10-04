import 'dart:convert';
import 'dart:typed_data';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/pages/editor.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class RuntimeConfigView extends ConsumerStatefulWidget {
  const RuntimeConfigView({super.key});

  @override
  ConsumerState<RuntimeConfigView> createState() => _RuntimeConfigViewState();
}

class _RuntimeConfigViewState extends ConsumerState<RuntimeConfigView> {
  final ValueNotifier<String?> _content = ValueNotifier<String?>(null);
  bool _loading = false;

  String _text(BuildContext context, String zh, String en) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(currentProfileIdProvider, (previous, next) {
      if (previous != next) {
        _load();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (_loading) return;
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) {
      _content.value = '';
      return;
    }
    _loading = true;
    _content.value = null;
    try {
      final yaml = await ref
          .read(setupActionProvider.notifier)
          .getRuntimeProfileWithId(profileId);
      if (!mounted) return;
      _content.value = yaml;
    } finally {
      _loading = false;
    }
  }

  Future<void> _copy() async {
    final content = _content.value;
    if (content == null || content.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    context.showNotifier(_text(context, '已复制运行时配置', 'Runtime config copied'));
  }

  Future<void> _export() async {
    final content = _content.value;
    if (content == null || content.isEmpty) return;
    final bytes = Uint8List.fromList(utf8.encode(content));
    await picker.saveFile('aetherclash-runtime.yaml', bytes);
  }

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _content,
      builder: (_, content, _) {
        return EditorPage(
          key: const ValueKey('runtime-config'),
          title: _text(context, '运行时配置', 'Runtime config'),
          content: content,
          actions: [
            IconButton(
              tooltip: _text(context, '刷新', 'Refresh'),
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: _text(context, '复制全部', 'Copy all'),
              onPressed: content == null || content.isEmpty ? null : _copy,
              icon: const Icon(Icons.copy_all_rounded),
            ),
            IconButton(
              tooltip: _text(context, '导出 YAML', 'Export YAML'),
              onPressed: content == null || content.isEmpty ? null : _export,
              icon: const Icon(Icons.download_rounded),
            ),
          ],
        );
      },
    );
  }
}
