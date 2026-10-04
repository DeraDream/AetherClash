const speedTestGroupName = '__AetherClash-SpeedTest__';
const speedTestListenerName = '__aetherclash-speedtest__';

/// A deterministic localhost-only port well away from the normal Clash ports.
///
/// The last three digits follow the configured mixed port so multiple local
/// profiles using different mixed ports are unlikely to share the same test
/// listener.
int speedTestListenerPortFor(int mixedPort) {
  final suffix = mixedPort.abs() % 1000;
  return 39000 + suffix;
}

/// Adds an internal selector and an isolated mixed listener used only by the
/// Network Info bandwidth test.
///
/// The listener points directly at [speedTestGroupName], so speed-test traffic
/// never needs to change the user's current rule/global/direct mode or selected
/// proxy. The group is hidden from the regular proxy UI.
void installSpeedTestRuntimeConfig(
  Map<String, dynamic> config, {
  required int mixedPort,
}) {
  final rawGroups = config['proxy-groups'];
  final groups = rawGroups is List
      ? List<dynamic>.from(rawGroups)
      : <dynamic>[];
  groups.removeWhere(
    (item) => item is Map && item['name'] == speedTestGroupName,
  );
  groups.add(<String, dynamic>{
    'name': speedTestGroupName,
    'type': 'select',
    'include-all': true,
    'exclude-type': 'Direct|Reject|Compatible|Pass',
    'hidden': true,
  });
  config['proxy-groups'] = groups;

  final rawListeners = config['listeners'];
  final listeners = rawListeners is List
      ? List<dynamic>.from(rawListeners)
      : <dynamic>[];
  listeners.removeWhere(
    (item) => item is Map && item['name'] == speedTestListenerName,
  );
  listeners.add(<String, dynamic>{
    'name': speedTestListenerName,
    'type': 'mixed',
    'listen': '127.0.0.1',
    'port': speedTestListenerPortFor(mixedPort),
    'proxy': speedTestGroupName,
    // Explicitly override global proxy authentication for this localhost-only
    // internal listener.
    'users': <dynamic>[],
    'udp': false,
  });
  config['listeners'] = listeners;
}
