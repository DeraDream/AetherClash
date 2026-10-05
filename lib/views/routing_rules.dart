import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/control/tiles.dart';
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
  final Set<int> _updatingRuleIds = <int>{};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _text(BuildContext context, String zh, String en) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  String _normalizeRuleKind(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  int _hitsFor(Rule rule, List<TrackerInfo> requests) {
    final ruleKind = _normalizeRuleKind(rule.ruleAction.value);
    final payload = rule.realContent;
    return requests.where((request) {
      if (_normalizeRuleKind(request.rule) != ruleKind) {
        return false;
      }
      if (payload == null || payload.isEmpty) {
        return true;
      }
      return request.rulePayload == payload;
    }).length;
  }

  bool _matches(Rule rule, String query) {
    if (query.isEmpty) return true;
    final value = [
      rule.ruleAction.value,
      rule.realContent ?? '',
      rule.realTarget ?? '',
      rule.rawValue,
    ].join(' ').toLowerCase();
    return value.contains(query.toLowerCase());
  }

  Future<void> _setRuleEnabled({
    required int profileId,
    required Rule rule,
    required bool enabled,
  }) async {
    if (_updatingRuleIds.contains(rule.id)) return;
    setState(() => _updatingRuleIds.add(rule.id));
    try {
      final notifier = ref.read(
        profileDisabledRuleIdsProvider(profileId).notifier,
      );
      if (enabled) {
        await notifier.delRule(rule.id);
      } else {
        await notifier.putRule(rule);
      }
      await ref.read(setupActionProvider.notifier).applyProfile(force: true);
    } catch (error) {
      if (mounted) {
        context.showNotifier(
          userFacingErrorMessage(error, context.appLocalizations),
          level: MessageLevel.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updatingRuleIds.remove(rule.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileId = ref.watch(currentProfileIdProvider);
    final requests = ref.watch(requestsProvider).list;

    return CommonScaffold(
      title: _text(context, '规则', 'Rules'),
      body: profileId == null
          ? NullStatus(
              label: _text(context, '请先选择配置文件', 'Select a profile first'),
              illustration: NullStatusIllustration.rules,
            )
          : ref.watch(clashConfigProvider(profileId)).when(
              loading: () => const Center(child: CommonCircleLoading()),
              error: (error, _) => Center(
                child: Text(
                  userFacingErrorMessage(error, context.appLocalizations),
                ),
              ),
              data: (config) {
                final disabledIds =
                    (ref
                                .watch(
                                  profileDisabledRuleIdsProvider(profileId),
                                )
                                .value ??
                            const <int>[])
                        .toSet();
                final query = _searchController.text.trim();
                final rules = config.rules
                    .where((rule) => _matches(rule, query))
                    .toList();

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                      child: Column(
                        children: [
                          const OutboundModeSwitch(height: 38),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            inputFormatters:
                                TextInputLimits.limit(TextInputLimits.search),
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
                                      tooltip: context.appLocalizations.clear,
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: NullStatusSwitcher(
                        isEmpty: rules.isEmpty,
                        nullStatus: NullStatus(
                          label: query.isEmpty
                              ? context.appLocalizations.nullTip(
                                  context.appLocalizations.rule,
                                )
                              : _text(
                                  context,
                                  '没有匹配的规则',
                                  'No matching rules',
                                ),
                          illustration: NullStatusIllustration.rules,
                        ),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: rules.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final rule = rules[index];
                            final hits = _hitsFor(rule, requests);
                            final total = requests.length;
                            final percent = total == 0
                                ? 0.0
                                : hits * 100 / total;
                            final enabled = !disabledIds.contains(rule.id);
                            final updating = _updatingRuleIds.contains(rule.id);
                            return _RoutingRuleItem(
                              rule: rule,
                              enabled: enabled,
                              updating: updating,
                              hits: hits,
                              total: total,
                              percent: percent,
                              onChanged: (value) => _setRuleEnabled(
                                profileId: profileId,
                                rule: rule,
                                enabled: value,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _RoutingRuleItem extends StatelessWidget {
  const _RoutingRuleItem({
    required this.rule,
    required this.enabled,
    required this.updating,
    required this.hits,
    required this.total,
    required this.percent,
    required this.onChanged,
  });

  final Rule rule;
  final bool enabled;
  final bool updating;
  final int hits;
  final int total;
  final double percent;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final glass = context.glass;
    final primary = context.colorScheme.primary;
    final payload = rule.realContent?.isNotEmpty == true
        ? rule.realContent!
        : rule.ruleAction.value;
    final target = rule.realTarget ?? '';

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
                    message: rule.rawValue,
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
                    onChanged: onChanged,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Wrap(
              spacing: 6,
              runSpacing: 5,
              children: [
                MetaChip(label: rule.ruleAction.value),
                if (target.isNotEmpty) MetaChip(label: target),
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
