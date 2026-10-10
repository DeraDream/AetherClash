import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/database/database.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoutingRulesView extends ConsumerStatefulWidget {
  const RoutingRulesView({super.key});

  @override
  ConsumerState<RoutingRulesView> createState() => _RoutingRulesViewState();
}

class _RoutingRulesViewState extends ConsumerState<RoutingRulesView> {
  final _searchController = TextEditingController();
  final Set<int> _updatingIndexes = <int>{};
  Timer? _timer;
  List<RuntimeRule> _rules = const [];
  bool _loading = true;
  Object? _error;
  bool _refreshing = false;

  String _text(BuildContext context, String zh, String en) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(currentProfileIdProvider, (previous, next) {
      if (previous != next) {
        _refresh(forceLoading: true);
      }
    });
    ref.listenManual(initProvider, (previous, next) {
      if (previous != next) {
        _refresh(forceLoading: true);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh(forceLoading: true);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh({bool forceLoading = false}) async {
    if (!mounted || _refreshing) return;
    final ready =
        ref.read(initProvider) && ref.read(currentProfileIdProvider) != null;
    if (!ready) {
      if (_rules.isNotEmpty || _error != null || !_loading) {
        setState(() {
          _rules = const [];
          _error = null;
          _loading = false;
        });
      }
      return;
    }
    if (forceLoading && _rules.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    _refreshing = true;
    try {
      var rules = await ref.read(coreHandlerProvider).getRules();
      final profileId = ref.read(currentProfileIdProvider);
      if (profileId != null) {
        final disabledIds =
            (await database.rulesDao
                    .queryProfileDisabledRules(profileId)
                    .map((item) => item.id)
                    .get())
                .toSet();
        var changed = false;
        for (final rule in rules) {
          final extra = rule.extra;
          if (extra == null) continue;
          final shouldDisable = disabledIds.contains(rule.overlayId);
          if (extra.disabled == shouldDisable) continue;
          final applied = await ref
              .read(coreHandlerProvider)
              .setRuleDisabled(rule.index, shouldDisable);
          changed = changed || applied;
        }
        if (changed) {
          rules = await ref.read(coreHandlerProvider).getRules();
        }
      }
      if (!mounted) return;
      setState(() {
        _rules = rules;
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error;
      });
    } finally {
      _refreshing = false;
    }
  }

  bool _matches(RuntimeRule rule, String query) {
    if (query.isEmpty) return true;
    final value = [rule.type, rule.payload, rule.proxy].join(' ').toLowerCase();
    return value.contains(query.toLowerCase());
  }

  Future<void> _setEnabled(RuntimeRule rule, bool enabled) async {
    final extra = rule.extra;
    final profileId = ref.read(currentProfileIdProvider);
    if (extra == null ||
        profileId == null ||
        _updatingIndexes.contains(rule.index)) {
      return;
    }
    setState(() => _updatingIndexes.add(rule.index));
    final storedRule = rule.storedOverlayRule;
    try {
      if (enabled) {
        await database.rulesDao.delDisabledLink(profileId, storedRule.id);
      } else {
        await database.rulesDao.putProfileDisabledRule(profileId, storedRule);
      }
      ref.invalidate(profileDisabledRuleIdsProvider(profileId));
      final success = await ref
          .read(coreHandlerProvider)
          .setRuleDisabled(rule.index, !enabled);
      if (!success) {
        if (enabled) {
          await database.rulesDao.putProfileDisabledRule(profileId, storedRule);
        } else {
          await database.rulesDao.delDisabledLink(profileId, storedRule.id);
        }
        ref.invalidate(profileDisabledRuleIdsProvider(profileId));
        throw StateError(
          _text(
            context,
            '当前规则不支持运行时开关',
            'This rule cannot be toggled at runtime',
          ),
        );
      }
      await _refresh();
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

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim();
    final rules = _rules.where((rule) => _matches(rule, query)).toList();

    return CommonScaffold(
      title: _text(context, '规则', 'Rules'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              inputFormatters: TextInputLimits.limit(TextInputLimits.search),
              decoration: InputDecoration(
                hintText: _text(
                  context,
                  '搜索规则、策略或规则类型',
                  'Search rule, policy or type',
                ),
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: _text(context, '清除搜索', 'Clear search'),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
          ),
          Expanded(child: _buildBody(context, rules, query)),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<RuntimeRule> rules,
    String query,
  ) {
    if (_loading) {
      return const Center(child: CommonCircleLoading());
    }
    final error = _error;
    if (error != null && _rules.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                userFacingErrorMessage(error, context.appLocalizations),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(_text(context, '重试', 'Retry')),
              ),
            ],
          ),
        ),
      );
    }
    if (rules.isEmpty) {
      return NullStatus(
        label: query.isEmpty
            ? _text(context, '当前没有运行中的规则', 'No runtime rules')
            : _text(context, '没有匹配的规则', 'No matching rules'),
        illustration: NullStatusIllustration.rules,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      itemCount: rules.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final rule = rules[index];
        return _RuntimeRuleItem(
          rule: rule,
          updating: _updatingIndexes.contains(rule.index),
          onChanged: (enabled) => _setEnabled(rule, enabled),
        );
      },
    );
  }
}

class _RuntimeRuleItem extends StatelessWidget {
  const _RuntimeRuleItem({
    required this.rule,
    required this.updating,
    required this.onChanged,
  });

  final RuntimeRule rule;
  final bool updating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final primary = context.colorScheme.primary;
    final extra = rule.extra;
    final hits = extra?.hitCount ?? 0;
    final misses = extra?.missCount ?? 0;
    final total = hits + misses;
    final percent = total == 0 ? 0.0 : hits * 100 / total;
    final enabled = !(extra?.disabled ?? false);
    final payload = rule.payload.isNotEmpty ? rule.payload : rule.type;

    return GlassSurface(
      borderRadius: AppRadius.small,
      elevated: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Tooltip(
                    message: [
                      rule.type,
                      rule.payload,
                      rule.proxy,
                    ].where((item) => item.isNotEmpty).join(','),
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
                ),
                const SizedBox(width: 10),
                if (updating)
                  const SizedBox.square(
                    dimension: 22,
                    child: Padding(
                      padding: EdgeInsets.all(2),
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
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: [
                MetaChip(label: rule.type),
                if (rule.proxy.isNotEmpty) MetaChip(label: rule.proxy),
                if (rule.size >= 0) MetaChip(label: rule.size.toString()),
              ],
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Icon(
                  hits > 0
                      ? Icons.check_circle_outline_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 15,
                  color: hits > 0 ? primary : glass.secondaryLabel,
                ),
                const SizedBox(width: 5),
                Text(
                  hits > 0
                      ? (Localizations.localeOf(context).languageCode == 'zh'
                            ? '已命中'
                            : 'Matched')
                      : (Localizations.localeOf(context).languageCode == 'zh'
                            ? '未命中'
                            : 'Not matched'),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: hits > 0 ? primary : glass.secondaryLabel,
                  ),
                ),
                const Spacer(),
                Text(
                  '$hits / $total',
                  style: context.textTheme.bodySmall?.copyWith(
                    fontFamily: FontFamily.jetBrainsMono.value,
                    color: glass.secondaryLabel,
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 56,
                  child: Text(
                    '${percent.toStringAsFixed(1)}%',
                    textAlign: TextAlign.end,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontFamily: FontFamily.jetBrainsMono.value,
                      color: glass.secondaryLabel,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
