import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class RoutingRulesView extends ConsumerStatefulWidget {
  const RoutingRulesView({super.key});

  @override
  ConsumerState<RoutingRulesView> createState() => _RoutingRulesViewState();
}

class _RoutingRulesViewState extends ConsumerState<RoutingRulesView> {
  final _searchController = TextEditingController();
  final Set<int> _updatingIndexes = <int>{};
  List<RuntimeRule>? _rules;
  Object? _error;
  Timer? _pollTimer;
  bool _loading = false;

  String _text(String zh, String en) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(currentProfileIdProvider, (previous, next) {
      if (previous != next) {
        _loadRules(showLoading: true);
      }
    });
    ref.listenManual(coreStatusProvider, (previous, next) {
      if (previous != next) {
        _loadRules(showLoading: true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRules(showLoading: true);
      _pollTimer = Timer.periodic(
        const Duration(seconds: 2),
        (_) => _loadRules(),
      );
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRules({bool showLoading = false}) async {
    if (_loading || !mounted) return;
    _loading = true;
    if (showLoading && _rules == null) {
      setState(() => _error = null);
    }
    try {
      final rules = await ref.read(coreHandlerProvider).getRules();
      if (!mounted) return;
      setState(() {
        _rules = rules;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
    } finally {
      _loading = false;
    }
  }

  bool _matches(RuntimeRule rule, String query) {
    if (query.isEmpty) return true;
    final haystack = [
      rule.type,
      rule.payload,
      rule.proxy,
    ].join(' ').toLowerCase();
    return haystack.contains(query.toLowerCase());
  }

  Future<void> _setEnabled(RuntimeRule rule, bool enabled) async {
    if (_updatingIndexes.contains(rule.index)) return;
    setState(() => _updatingIndexes.add(rule.index));
    try {
      final changed = await ref
          .read(coreHandlerProvider)
          .setRuleDisabled(rule.index, !enabled);
      if (!changed) {
        throw MessageException(
          _text(
            '当前内核没有为这条规则提供运行时开关。',
            'The current core does not expose a runtime toggle for this rule.',
          ),
        );
      }
      await _loadRules();
    } catch (error) {
      if (mounted) {
        context.showNotifier(
          userFacingErrorMessage(error, context.appLocalizations),
          level: MessageLevel.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingIndexes.remove(rule.index));
      }
    }
  }

  String _relativeTime(DateTime? value) {
    if (value == null) {
      return _text('从未命中', 'Never');
    }
    final diff = DateTime.now().difference(value.toLocal());
    if (diff.isNegative || diff.inSeconds < 60) {
      return _text('刚刚', 'Just now');
    }
    if (diff.inMinutes < 60) {
      return _text('${diff.inMinutes} 分钟前', '${diff.inMinutes}m ago');
    }
    if (diff.inHours < 24) {
      return _text('${diff.inHours} 小时前', '${diff.inHours}h ago');
    }
    return _text('${diff.inDays} 天前', '${diff.inDays}d ago');
  }

  DateTime? _lastActivity(RuntimeRuleExtra? extra) {
    if (extra == null) return null;
    final hitAt = extra.hitAt;
    final missAt = extra.missAt;
    if (hitAt == null) return missAt;
    if (missAt == null) return hitAt;
    return hitAt.isAfter(missAt) ? hitAt : missAt;
  }

  @override
  Widget build(BuildContext context) {
    final rules = _rules;
    final error = _error;
    final query = _searchController.text.trim();
    final filtered = rules
        ?.where((rule) => _matches(rule, query))
        .toList(growable: false);

    return CommonScaffold(
      title: _text('规则', 'Rules'),
      isLoading: _loading && rules != null,
      actions: [
        IconButton(
          tooltip: _text('刷新', 'Refresh'),
          onPressed: _loading ? null : () => _loadRules(showLoading: true),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              inputFormatters: TextInputLimits.limit(TextInputLimits.search),
              decoration: InputDecoration(
                hintText: _text(
                  '搜索规则、策略或规则类型',
                  'Search rule, policy or type',
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: context.appLocalizations.clearSearch,
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Expanded(
            child: switch ((rules, error)) {
              (null, null) => const Center(child: CommonCircleLoading()),
              (null, Object error) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      userFacingErrorMessage(
                        error,
                        context.appLocalizations,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              _ => NullStatusSwitcher(
                  isEmpty: filtered?.isEmpty ?? true,
                  nullStatus: NullStatus(
                    label: query.isEmpty
                        ? context.appLocalizations.nullTip(
                            context.appLocalizations.rule,
                          )
                        : _text('没有匹配的规则', 'No matching rules'),
                    illustration: NullStatusIllustration.rules,
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: filtered?.length ?? 0,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final rule = filtered![index];
                      return _RuntimeRuleItem(
                        rule: rule,
                        updating: _updatingIndexes.contains(rule.index),
                        lastActivity: _relativeTime(
                          _lastActivity(rule.extra),
                        ),
                        onChanged: (enabled) =>
                            _setEnabled(rule, enabled),
                      );
                    },
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}

class _RuntimeRuleItem extends StatelessWidget {
  const _RuntimeRuleItem({
    required this.rule,
    required this.updating,
    required this.lastActivity,
    required this.onChanged,
  });

  final RuntimeRule rule;
  final bool updating;
  final String lastActivity;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final extra = rule.extra;
    final hitCount = extra?.hitCount ?? 0;
    final missCount = extra?.missCount ?? 0;
    final total = hitCount + missCount;
    final rate = total == 0 ? 0.0 : hitCount * 100 / total;
    final enabled = !(extra?.disabled ?? false);
    final payload = rule.payload.isEmpty ? rule.type : rule.payload;

    return Opacity(
      opacity: enabled ? 1 : 0.56,
      child: GlassSurface(
        borderRadius: AppRadius.small,
        elevated: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Tooltip(
                      message: payload,
                      child: Text(
                        payload,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall?.copyWith(
                          fontFamily: FontFamily.jetBrainsMono.value,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 6,
                      runSpacing: 5,
                      children: [
                        MetaChip(label: rule.type),
                        if (rule.proxy.isNotEmpty)
                          MetaChip(label: rule.proxy),
                        if (rule.size >= 0)
                          MetaChip(label: rule.size.toString()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (extra != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      lastActivity,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: glass.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$hitCount/$total',
                          style: context.textTheme.bodySmall?.copyWith(
                            fontFamily: FontFamily.jetBrainsMono.value,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        MetaChip(label: '${rate.toStringAsFixed(1)}%'),
                      ],
                    ),
                  ],
                ),
              const SizedBox(width: 10),
              if (updating)
                const SizedBox.square(
                  dimension: 36,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CommonCircleLoading(),
                  ),
                )
              else
                Switch(
                  value: enabled,
                  onChanged: extra == null ? null : onChanged,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
