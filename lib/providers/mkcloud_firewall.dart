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
  Uri? _endpoint;

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
    _endpoint = _endpointOf(_setting.apiUrl);
    pollNow();
  }

  Future<void> configure(String apiUrl, String apiKey) async {
    final endpoint = _endpointOf(apiUrl);
    _endpoint = endpoint;
    final setting = _setting;
    if (setting.apiUrl != apiUrl || setting.apiKey != apiKey) {
      ref
          .read(mkcloudFirewallSettingProvider.notifier)
          .update((it) => it.copyWith(apiUrl: apiUrl, apiKey: apiKey));
    }
    if (!_started || endpoint == null || apiKey.isEmpty || _inFlight) return;
    _timer?.cancel();
    try {
      await _refreshDirectRoutes();
      await query();
    } catch (_) {
      _setRoutePreparationError();
    }
  }

  void pollNow() => unawaited(_run(MkcloudRunKind.poll));
  Future<void> query() => _run(MkcloudRunKind.query);
  Future<void> whitelist() => _run(MkcloudRunKind.whitelist);

  /// Select a province locally. The selection is applied only when the user
  /// explicitly runs the whitelist action.
  void selectProvince(String province) {
    if (state.result?.mode != 'province' || _inFlight) return;
    state = state.copyWith(selectedProvince: province);
  }

  Future<bool> setProvince(String province) =>
      _mutate({'api': 1, 'api_action': 'set_province', 'province': province});

  Future<bool> addIp(String ip) =>
      _mutate({'api': 1, 'api_action': 'add_whitelist', 'ip': ip});

  Future<bool> switchToIp() async {
    final setting = _setting;
    if (!_started || setting.apiKey.isEmpty || _endpoint == null || _inFlight) {
      return false;
    }
    _inFlight = true;
    _timer?.cancel();
    state = state.copyWith(isRunning: true);
    try {
      final ip = await ref.read(mkcloudFirewallClientProvider).currentIp();
      return await _mutate({
        'api': 1,
        'api_action': 'add_whitelist',
        'ip': ip,
      }, isLocked: true);
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

  Future<bool> deleteIp(String ip) =>
      _mutate({'api': 1, 'api_action': 'delete_whitelist', 'ip': ip});

  Future<void> onNetworkChanged() async {
    if (!_started || !_setting.enable || _endpoint == null) return;
    ref.read(mkcloudFirewallClientProvider).reset();
    try {
      await _refreshDirectRoutes();
    } catch (_) {
      _setRoutePreparationError();
      return;
    }
    pollNow();
  }

  Future<void> _onSettingChanged(
    MkcloudFirewallProps? previous,
    MkcloudFirewallProps next,
  ) async {
    if (!_started || previous == null || previous == next) return;
    if (previous.enable != next.enable) {
      _timer?.cancel();
      if (next.enable && _endpoint != null) {
        try {
          await _refreshDirectRoutes();
          await whitelist();
        } catch (_) {
          _setRoutePreparationError();
        }
      }
      return;
    }
    if (previous.pollSeconds != next.pollSeconds && !_inFlight) _schedule();
  }

  Uri? _endpointOf(String value) {
    final endpoint = Uri.tryParse(value.trim());
    if (endpoint == null ||
        endpoint.scheme != 'https' ||
        endpoint.host.isEmpty) {
      return null;
    }
    return endpoint;
  }

  Future<void> _refreshDirectRoutes() async {
    final endpoint = _endpoint;
    if (endpoint == null) return;
    final cidrs = await ref
        .read(mkcloudFirewallClientProvider)
        .directCidrs(endpoint);
    final notifier = ref.read(mkcloudFirewallSettingProvider.notifier);
    final didChange =
        !_setting.directCidrs.toSet().containsAll(cidrs) ||
        cidrs.toSet().length != _setting.directCidrs.toSet().length;
    if (!didChange) return;
    notifier.update((it) => it.copyWith(directCidrs: cidrs));
    await ref.read(setupActionProvider.notifier).applyProfile(silence: true);
  }

  void _setRoutePreparationError() {
    state = MkcloudFirewallState(
      lastRunAt: DateTime.now(),
      lastRunKind: MkcloudRunKind.whitelist,
      result: const MkcloudResult(
        type: MkcloudResultType.error,
        message: 'route_preparation_failed',
      ),
    );
  }

  Future<void> _run(MkcloudRunKind kind) async {
    final setting = _setting;
    final endpoint = _endpoint;
    if (!_started || setting.apiKey.isEmpty || endpoint == null || _inFlight) {
      return;
    }
    if (kind == MkcloudRunKind.poll && !setting.enable) return;
    _inFlight = true;
    _timer?.cancel();
    state = state.copyWith(isRunning: true);
    try {
      final client = ref.read(mkcloudFirewallClientProvider);
      final initial = await client.post(
        endpoint,
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
            result = mkcloudResultOf(
              await client.post(
                endpoint,
                apiKey: setting.apiKey,
                body: {'api': 1, 'api_action': 'add_whitelist', 'ip': ip},
              ),
              currentIp: ip,
            ).copyWith(type: MkcloudResultType.applied);
          } else {
            result = result.copyWith(type: MkcloudResultType.applied);
          }
        } else if (result.mode == 'province' && result.province != null) {
          final province = kind == MkcloudRunKind.whitelist
              ? state.selectedProvince ?? result.province!
              : result.province!;
          result = mkcloudResultOf(
            await client.post(
              endpoint,
              apiKey: setting.apiKey,
              body: {
                'api': 1,
                'api_action': 'set_province',
                'province': province,
              },
            ),
          ).copyWith(type: MkcloudResultType.applied);
        }
      }
      state = MkcloudFirewallState(
        selectedProvince: kind == MkcloudRunKind.whitelist
            ? null
            : state.selectedProvince,
        lastRunAt: DateTime.now(),
        lastRunKind: kind,
        result: result,
      );
    } catch (error) {
      state = MkcloudFirewallState(
        selectedProvince: null,
        lastRunAt: DateTime.now(),
        lastRunKind: kind,
        result: MkcloudResult(type: MkcloudResultType.error, message: '$error'),
      );
    } finally {
      _inFlight = false;
      _schedule();
    }
  }

  Future<bool> _mutate(
    Map<String, Object?> body, {
    bool isLocked = false,
  }) async {
    final setting = _setting;
    final endpoint = _endpoint;
    if (!_started ||
        setting.apiKey.isEmpty ||
        endpoint == null ||
        (!isLocked && _inFlight)) {
      return false;
    }
    if (!isLocked) {
      _inFlight = true;
      _timer?.cancel();
      state = state.copyWith(isRunning: true);
    }
    try {
      final client = ref.read(mkcloudFirewallClientProvider);
      final response = await client.post(
        endpoint,
        apiKey: setting.apiKey,
        body: body,
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
      if (!isLocked) {
        _inFlight = false;
        _schedule();
      }
    }
  }

  void _schedule() {
    _timer?.cancel();
    if (_started &&
        _endpoint != null &&
        _setting.enable &&
        _setting.apiKey.isNotEmpty) {
      _timer = Timer(Duration(seconds: _setting.pollSeconds), pollNow);
    }
  }
}
