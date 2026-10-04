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

    final listeners = List<dynamic>.from(config['listeners'] as List);
    final speedListeners = listeners
        .where((item) => item is Map && item['name'] == speedTestListenerName)
        .toList();
    expect(speedListeners, hasLength(1));
    expect(speedListeners.single['listen'], '127.0.0.1');
    expect(speedListeners.single['port'], 43930);
    expect(speedListeners.single['proxy'], speedTestGroupName);
  });
}
