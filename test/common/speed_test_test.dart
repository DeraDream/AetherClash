import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/speed_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('speed-test listener port follows the mixed port deterministically', () {
    expect(speedTestListenerPortFor(7890), 43930);
    expect(speedTestListenerPortFor(17890), 45930);
    expect(speedTestListenerPortFor(7891), 43967);
  });

  test('runtime config gets one hidden speed-test group and listener', () {
    final config = <String, dynamic>{
      'proxy-groups': <dynamic>[
        <String, dynamic>{'name': 'Proxy', 'type': 'select'},
        <String, dynamic>{'name': speedTestGroupName, 'type': 'select'},
      ],
      'listeners': <dynamic>[
        <String, dynamic>{
          'name': speedTestListenerName,
          'type': 'mixed',
          'port': 1,
        },
      ],
    };

    installSpeedTestRuntimeConfig(config, mixedPort: 7890);

    final groups = List<dynamic>.from(config['proxy-groups'] as List);
    final speedGroups = groups
        .where((item) => item is Map && item['name'] == speedTestGroupName)
        .toList();
    expect(speedGroups, hasLength(1));
    expect(speedGroups.single['hidden'], isTrue);
    expect(speedGroups.single['include-all'], isTrue);
    expect(speedGroups.single['proxies'], contains('DIRECT'));

    final listeners = List<dynamic>.from(config['listeners'] as List);
    final speedListeners = listeners
        .where((item) => item is Map && item['name'] == speedTestListenerName)
        .toList();
    expect(speedListeners, hasLength(1));
    expect(speedListeners.single['listen'], '127.0.0.1');
    expect(speedListeners.single['port'], 43930);
    expect(speedListeners.single['proxy'], speedTestGroupName);
  });

  test('decodes plain and gzip Speedtest server JSON', () {
    const body =
        '[{"id":"1","name":"Singapore","country":"Singapore",'
        '"sponsor":"ISP","url":"https://example.com/upload.php",'
        '"host":"example.com:443"}]';

    final plain = decodeSpeedTestJsonBody(utf8.encode(body));
    final compressed = decodeSpeedTestJsonBody(gzip.encode(utf8.encode(body)));

    expect(plain, isA<List<dynamic>>());
    expect(compressed, equals(plain));
    expect((compressed as List).single['id'], '1');
  });

  test('SpeedTestServer derives classic Speedtest endpoints', () {
    const server = SpeedTestServer(
      id: '1',
      name: 'Singapore',
      country: 'Singapore',
      sponsor: 'Example ISP',
      url: 'https://example.com/speedtest/upload.php',
      host: 'example.com:443',
    );

    expect(
      server.downloadUri(1, 2).path,
      '/speedtest/random4000x4000.jpg',
    );
    expect(server.latencyUri.path, '/speedtest/latency.txt');
    expect(server.label, 'Example ISP · Singapore, Singapore');
  });
}
