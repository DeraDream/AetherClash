import 'dart:async';

import 'package:fl_clash/common/mkcloud_firewall.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/mkcloud_firewall.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class _FakeMkcloudClient extends MkcloudDirectTransport {
  final requests = <String>[];
  final uris = <Uri>[];
  Completer<void>? gate;
  var mode = 'province';
  var province = 'jiangsu';

  @override
  Future<String> currentIp() async => '203.0.113.1';

  @override
  Future<List<String>> directCidrs(Uri apiUri) async => const [
    '203.0.113.2/32',
  ];

  @override
  Future<Map<String, Object?>> post(
    Uri uri, {
    required String apiKey,
    required Map<String, Object?> body,
  }) async {
    await gate?.future;
    uris.add(uri);
    final action = body['api_action']! as String;
    requests.add(action);
    if (action == 'add_whitelist') mode = 'ip';
    if (action == 'set_province') province = body['province']! as String;
    return {
      'code': 0,
      'data': {
        'mode': mode,
        'province': mode == 'province' ? province : null,
        'entries': const [],
        'count': 0,
        'limit': 10,
        'provinces': const [
          {'value': 'jiangsu', 'label': '江苏'},
          {'value': 'beijing', 'label': '北京'},
        ],
      },
    };
  }
}

const _setting = MkcloudFirewallProps(
  enable: true,
  apiKey: 'test-key',
  pollSeconds: 3600,
  directCidrs: ['203.0.113.2/32'],
);

final _endpoint = Uri.parse('https://example.test/mkcloud');

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

  Future<void> prepare(MkcloudFirewall notifier) async {
    notifier.start();
    await notifier.configure(_endpoint.toString(), _setting.apiKey);
  }

  tearDown(() => container.dispose());

  test(
    'a configured endpoint is used for the initial status request',
    () async {
      createContainer();
      final notifier = container.read(mkcloudFirewallProvider.notifier);

      await prepare(notifier);

      expect(client.uris, everyElement(_endpoint));
    },
  );

  test('stores the user-supplied endpoint with the local settings', () async {
    createContainer();
    final notifier = container.read(mkcloudFirewallProvider.notifier);
    const apiUrl = 'https://personal.example/firewall?id=42';

    await notifier.configure(apiUrl, 'personal-token');

    expect(container.read(mkcloudFirewallSettingProvider).apiUrl, apiUrl);
    expect(
      container.read(mkcloudFirewallSettingProvider).apiKey,
      'personal-token',
    );
  });

  test(
    'a poll exposes its busy state so conflicting actions are disabled',
    () async {
      createContainer();
      client.gate = Completer<void>();
      final notifier = container.read(mkcloudFirewallProvider.notifier);

      notifier.start();
      unawaited(notifier.configure(_endpoint.toString(), _setting.apiKey));
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

      await prepare(notifier);
      client.requests.clear();

      expect(await notifier.switchToIp(), isTrue);
      expect(client.mode, 'ip');
      expect(client.requests, ['add_whitelist']);
      expect(container.read(mkcloudFirewallProvider).result?.mode, 'ip');
    },
  );

  test(
    'a province selection stays local until whitelist is requested',
    () async {
      createContainer();
      final notifier = container.read(mkcloudFirewallProvider.notifier);

      await prepare(notifier);
      client.requests.clear();

      notifier.selectProvince('beijing');
      expect(
        container.read(mkcloudFirewallProvider).selectedProvince,
        'beijing',
      );
      expect(
        container.read(mkcloudFirewallProvider).result?.province,
        'jiangsu',
      );
      expect(client.requests, isEmpty);

      await notifier.whitelist();
      expect(client.province, 'beijing');
      expect(client.requests, ['get_provinces', 'set_province']);
      expect(
        container.read(mkcloudFirewallProvider).result?.province,
        'beijing',
      );
      expect(container.read(mkcloudFirewallProvider).selectedProvince, isNull);
    },
  );
}
