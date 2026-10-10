import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'generated/mkcloud_firewall.g.dart';

@Riverpod(keepAlive: true)
MkcloudDirectTransport mkcloudFirewallClient(Ref ref) =>
    MkcloudDirectTransport();

@Riverpod(keepAlive: true)
class MkcloudFirewall extends _$MkcloudFirewall {
  Timer? _timer;
  bool _started = false;
  bool _inFlight = false;

  MkcloudFirewallProps get _setting => ref.read(mkcloudFirewallSettingProvider);

  @override
  MkcloudFirewallState build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(mkcloudFirewallSettingProvider, _onSettingChanged);
    return const MkcloudFirewallState();
  }

  void start() {
    if (_started) return;
    _started = true;
    pollNow();
  }

  void pollNow() => unawaited(_run(MkcloudRunKind.poll));
  Future<void> query() => _run(MkcloudRunKind.query);
  Future<void> whitelist() => _run(MkcloudRunKind.whitelist);

  Future<bool> setProvince(String province) =>
      _mutate({'api': 1, 'api_action': 'set_province', 'province': province});

  Future<bool> addIp(String ip) =>
      _mutate({'api': 1, 'api_action': 'add_whitelist', 'ip': ip});

  Future<bool> switchToIp() async {
    try {
      final ip = await ref.read(mkcloudFirewallClientProvider).currentIp();
      return await addIp(ip);
    } catch (error) {
      state = MkcloudFirewallState(
        lastRunAt: DateTime.now(),
        lastRunKind: MkcloudRunKind.whitelist,
        result: MkcloudResult(type: MkcloudResultType.error, message: '$error'),
      );
      return false;
    }
  }

  Future<bool> deleteIp(String ip) =>
      _mutate({'api': 1, 'api_action': 'delete_whitelist', 'ip': ip});

  Future<void> onNetworkChanged() async {
    if (!_started || !_setting.enable) return;
    ref.read(mkcloudFirewallClientProvider).reset();
    try {
      await _refreshDirectRoutes();
    } catch (_) {}
    pollNow();
  }

  Future<void> _onSettingChanged(
    MkcloudFirewallProps? previous,
    MkcloudFirewallProps next,
  ) async {
    if (!_started || previous == null || previous == next) return;
    if (previous.enable != next.enable) {
      _timer?.cancel();
      if (next.enable) {
        await _refreshDirectRoutes();
        await whitelist();
      }
      return;
    }
    if (previous.apiKey != next.apiKey && next.apiKey.isNotEmpty) {
      await _refreshDirectRoutes();
      return;
    }
    if (previous.pollSeconds != next.pollSeconds && !_inFlight) _schedule();
  }

  Future<void> _refreshDirectRoutes() async {
    final cidrs = await resolveMkcloudDirectCidrs();
    final notifier = ref.read(mkcloudFirewallSettingProvider.notifier);
    if (!_setting.directCidrs.toSet().containsAll(cidrs) ||
        cidrs.toSet().length != _setting.directCidrs.toSet().length) {
      notifier.update((it) => it.copyWith(directCidrs: cidrs));
    }
    await ref.read(setupActionProvider.notifier).applyProfile(silence: true);
  }

  Future<void> _run(MkcloudRunKind kind) async {
    final setting = _setting;
    if (!_started || setting.apiKey.isEmpty || _inFlight) return;
    if (kind == MkcloudRunKind.poll && !setting.enable) return;
    _inFlight = true;
    _timer?.cancel();
    if (kind != MkcloudRunKind.poll) state = state.copyWith(isRunning: true);
    try {
      final client = ref.read(mkcloudFirewallClientProvider);
      final initial = await client.post(
        Uri.parse(mkcloudApiUri),
        apiKey: setting.apiKey,
        body: {'api': 1, 'api_action': 'get_provinces'},
      );
      var result = mkcloudResultOf(initial);
      if (kind != MkcloudRunKind.query) {
        if (result.mode == 'ip') {
          final ip = await client.currentIp();
          result = result.copyWith(currentIp: ip);
          final exists = result.entries.any(
            (it) => it.cidr == '$ip/32' || it.cidr == ip,
          );
          if (!exists) {
            await client.post(
              Uri.parse(mkcloudApiUri),
              apiKey: setting.apiKey,
              body: {'api': 1, 'api_action': 'add_whitelist', 'ip': ip},
            );
            result = mkcloudResultOf(
              await client.post(
                Uri.parse(mkcloudApiUri),
                apiKey: setting.apiKey,
                body: {'api': 1, 'api_action': 'get_provinces'},
              ),
              currentIp: ip,
            ).copyWith(type: MkcloudResultType.applied);
          } else {
            result = result.copyWith(type: MkcloudResultType.applied);
          }
        } else if (result.mode == 'province' && result.province != null) {
          await client.post(
            Uri.parse(mkcloudApiUri),
            apiKey: setting.apiKey,
            body: {
              'api': 1,
              'api_action': 'set_province',
              'province': result.province!,
            },
          );
          result = mkcloudResultOf(
            await client.post(
              Uri.parse(mkcloudApiUri),
              apiKey: setting.apiKey,
              body: {'api': 1, 'api_action': 'get_provinces'},
            ),
          ).copyWith(type: MkcloudResultType.applied);
        }
      }
      state = MkcloudFirewallState(
        lastRunAt: DateTime.now(),
        lastRunKind: kind,
        result: result,
      );
    } catch (error) {
      state = MkcloudFirewallState(
        lastRunAt: DateTime.now(),
        lastRunKind: kind,
        result: MkcloudResult(type: MkcloudResultType.error, message: '$error'),
      );
    } finally {
      _inFlight = false;
      _schedule();
    }
  }

  Future<bool> _mutate(Map<String, Object?> body) async {
    final setting = _setting;
    if (!_started || setting.apiKey.isEmpty || _inFlight) {
      return false;
    }
    _inFlight = true;
    _timer?.cancel();
    state = state.copyWith(isRunning: true);
    try {
      final client = ref.read(mkcloudFirewallClientProvider);
      await client.post(
        Uri.parse(mkcloudApiUri),
        apiKey: setting.apiKey,
        body: body,
      );
      final response = await client.post(
        Uri.parse(mkcloudApiUri),
        apiKey: setting.apiKey,
        body: {'api': 1, 'api_action': 'get_provinces'},
      );
      state = MkcloudFirewallState(
        lastRunAt: DateTime.now(),
        lastRunKind: MkcloudRunKind.whitelist,
        result: mkcloudResultOf(
          response,
        ).copyWith(type: MkcloudResultType.applied),
      );
      return true;
    } catch (error) {
      state = MkcloudFirewallState(
        lastRunAt: DateTime.now(),
        lastRunKind: MkcloudRunKind.whitelist,
        result: MkcloudResult(type: MkcloudResultType.error, message: '$error'),
      );
      return false;
    } finally {
      _inFlight = false;
      _schedule();
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (_started && _setting.enable && _setting.apiKey.isNotEmpty) {
      _timer = Timer(Duration(seconds: _setting.pollSeconds), pollNow);
    }
  }
}
