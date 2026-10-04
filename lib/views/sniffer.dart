import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class SnifferView extends ConsumerStatefulWidget {
  const SnifferView({super.key});

  @override
  ConsumerState<SnifferView> createState() => _SnifferViewState();
}

class _SnifferViewState extends ConsumerState<SnifferView> {
  Sniffer _config = const Sniffer();
  bool _loading = true;

  String _text(BuildContext context, String zh, String en) {
    return Localizations.localeOf(context).languageCode == 'zh' ? zh : en;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final config = await preferences.getSnifferConfig();
    if (!mounted) return;
    setState(() {
      _config = config;
      _loading = false;
    });
  }

  Sniffer _withDefaultProtocols(Sniffer config) {
    final sniff = Map<String, SnifferConfig>.from(config.sniff);
    sniff.putIfAbsent(
      'HTTP',
      () => const SnifferConfig(ports: ['80', '8080-8880']),
    );
    sniff.putIfAbsent(
      'TLS',
      () => const SnifferConfig(ports: ['443', '8443']),
    );
    sniff.putIfAbsent(
      'QUIC',
      () => const SnifferConfig(ports: ['443', '8443']),
    );
    return config.copyWith(sniff: sniff);
  }

  Future<void> _save(Sniffer next) async {
    final normalized = _withDefaultProtocols(next);
    setState(() => _config = normalized);
    await preferences.saveSnifferConfig(normalized);
    ref.read(setupActionProvider.notifier).applyProfileDebounce();
  }

  List<String> _protocolPorts(String protocol) {
    final configured = _config.sniff[protocol]?.ports;
    if (configured != null && configured.isNotEmpty) {
      return configured;
    }
    return switch (protocol) {
      'HTTP' => const ['80', '8080-8880'],
      'TLS' => const ['443', '8443'],
      'QUIC' => const ['443', '8443'],
      _ => const [],
    };
  }

  Future<void> _updateProtocol(String protocol, List<String> ports) async {
    final sniff = Map<String, SnifferConfig>.from(_config.sniff);
    sniff[protocol] = SnifferConfig(
      ports: ports,
      overrideDest: sniff[protocol]?.overrideDest,
    );
    await _save(_config.copyWith(sniff: sniff));
  }

  Widget _toggle({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return DecorationListItem(
      minVerticalPadding: 9,
      contentPadding: const EdgeInsets.only(left: 16, right: 10),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      onPressed: () => onChanged(!value),
      trailing: Switch(value: value, onChanged: onChanged),
    );
  }

  Widget _listSetting({
    required String title,
    required String subtitle,
    required List<String> values,
    required ValueChanged<List<String>> onChanged,
  }) {
    return ListItem.open(
      title: Text(title),
      subtitle: Text(subtitle),
      widget: ListInputPage(
        title: title,
        items: values,
        itemMaxLength: 256,
        titleBuilder: (item) => Text(item),
      ),
      onChanged: (items) => onChanged(List<String>.from(items as List)),
    );
  }

  Widget _protocolSetting(String protocol) {
    final ports = _protocolPorts(protocol);
    return _listSetting(
      title: protocol,
      subtitle: ports.isEmpty
          ? _text(context, '未配置端口', 'No ports configured')
          : ports.join(', '),
      values: ports,
      onChanged: (values) => unawaited(_updateProtocol(protocol, values)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return BaseScaffold(
        title: _text(context, '流量嗅探', 'Sniffer'),
        body: const Center(child: CommonCircleLoading()),
      );
    }

    return CommonScaffold(
      title: _text(context, '流量嗅探', 'Sniffer'),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          18,
          4,
          18,
          24 + BottomInsetScope.of(context),
        ),
        children: [
          generateSectionV3(
            title: _text(context, '基本设置', 'General'),
            items: [
              _toggle(
                title: _text(context, '启用嗅探', 'Enable sniffer'),
                subtitle: _text(
                  context,
                  '从 HTTP / TLS / QUIC 流量中识别真实域名',
                  'Detect host names from HTTP / TLS / QUIC traffic',
                ),
                value: _config.enable,
                onChanged: (value) =>
                    unawaited(_save(_config.copyWith(enable: value))),
              ),
              _toggle(
                title: _text(context, '覆盖目标地址', 'Override destination'),
                subtitle: _text(
                  context,
                  '使用嗅探出的域名替换原始目标地址',
                  'Replace the original destination with the sniffed host',
                ),
                value: _config.overrideDest,
                onChanged: (value) =>
                    unawaited(_save(_config.copyWith(overrideDest: value))),
              ),
              _toggle(
                title: _text(context, '强制 DNS 映射', 'Force DNS mapping'),
                value: _config.forceDnsMapping,
                onChanged: (value) =>
                    unawaited(_save(_config.copyWith(forceDnsMapping: value))),
              ),
              _toggle(
                title: _text(context, '解析纯 IP 连接', 'Parse pure IP'),
                value: _config.parsePureIp,
                onChanged: (value) =>
                    unawaited(_save(_config.copyWith(parsePureIp: value))),
              ),
            ],
          ),
          generateSectionV3(
            title: _text(context, '协议与端口', 'Protocols and ports'),
            items: [
              _protocolSetting('HTTP'),
              _protocolSetting('TLS'),
              _protocolSetting('QUIC'),
            ],
          ),
          generateSectionV3(
            title: _text(context, '嗅探规则', 'Sniff rules'),
            items: [
              _listSetting(
                title: _text(context, '强制嗅探域名', 'Force domains'),
                subtitle: _text(
                  context,
                  '这些域名始终执行嗅探',
                  'Always sniff these domains',
                ),
                values: _config.forceDomain,
                onChanged: (values) =>
                    unawaited(_save(_config.copyWith(forceDomain: values))),
              ),
              _listSetting(
                title: _text(context, '跳过嗅探域名', 'Skip domains'),
                subtitle: _text(
                  context,
                  '这些域名不执行嗅探',
                  'Do not sniff these domains',
                ),
                values: _config.skipDomain,
                onChanged: (values) =>
                    unawaited(_save(_config.copyWith(skipDomain: values))),
              ),
              _listSetting(
                title: _text(context, '跳过来源地址', 'Skip source addresses'),
                subtitle: _text(context, '支持 IP / CIDR', 'IP / CIDR supported'),
                values: _config.skipSrcAddress,
                onChanged: (values) => unawaited(
                  _save(_config.copyWith(skipSrcAddress: values)),
                ),
              ),
              _listSetting(
                title: _text(context, '跳过目标地址', 'Skip destination addresses'),
                subtitle: _text(context, '支持 IP / CIDR', 'IP / CIDR supported'),
                values: _config.skipDstAddress,
                onChanged: (values) => unawaited(
                  _save(_config.copyWith(skipDstAddress: values)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
