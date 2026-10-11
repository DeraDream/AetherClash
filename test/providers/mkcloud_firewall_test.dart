import 'dart:async';

import 'package:fl_clash/common/mkcloud_firewall.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/mkcloud_firewall.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeMkcloudClient extends MkcloudDirectTransport {
  final requests = <String>[];
  Completer<void>? gate;
  var mode = 'province';

  @override
  Future<String> currentIp() async => '203.0.113.1';

  @override
  Future<Map<String, Object?>> post(
    Uri uri, {
    required String apiKey,
    required Map<String, Object?> body,
  }) async {
    await gate?.future;
    final action = body['api_action']! as String;
    requests.add(action);
    if (action == 'add_whitelist') mode = 'ip';
    return {
      'code': 0,
      'data': {
        'mode': mode,
        'province': mode == 'province' ? 'jiangsu' : null,
        'entries': const [],
        'count': 0,
        'limit': 10,
        'provinces': const [
          {'value': 'jiangsu', 'label': '江苏'},
        ],
      },
    };
  }
}

const _setting = MkcloudFirewallProps(
  enable: true,
  apiKey: 'test-key',
  pollSeconds: 3600,
);

void main() {
  late ProviderContainer container;
  late _FakeMkcloudClient client;

  void createContainer() {
    client = _FakeMkcloudClient();
    container = ProviderContainer(
      overrides: [
        mkcloudFirewallSettingProvider.overrideWithBuild((_, _) => _setting),
        mkcloudFirewallClientProvider.overrideWithValue(client),
      ],
    );
    container.read(mkcloudFirewallProvider);
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  tearDown(() => container.dispose());

  test(
    'a poll exposes its busy state so conflicting actions are disabled',
    () async {
      createContainer();
      client.gate = Completer<void>();
      final notifier = container.read(mkcloudFirewallProvider.notifier);

      notifier.start();
      await settle();
      expect(container.read(mkcloudFirewallProvider).isRunning, isTrue);
      expect(await notifier.switchToIp(), isFalse);

      client.gate!.complete();
      await settle();
      await settle();
      expect(container.read(mkcloudFirewallProvider).isRunning, isFalse);
    },
  );

  test(
    'switching from province mode adds the current exit as an IP rule',
    () async {
      createContainer();
      final notifier = container.read(mkcloudFirewallProvider.notifier);

      notifier.start();
      await settle();
      await settle();

      expect(await notifier.switchToIp(), isTrue);
      expect(client.mode, 'ip');
      expect(client.requests, contains('add_whitelist'));
      expect(container.read(mkcloudFirewallProvider).result?.mode, 'ip');
    },
  );
}
