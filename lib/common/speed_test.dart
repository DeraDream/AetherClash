const speedTestGroupName = '__AetherClash-SpeedTest__';
const speedTestListenerName = '__aetherclash-speedtest__';

/// A deterministic localhost-only port well away from the normal Clash ports.
///
/// The mixed port is spread across an 8k range so separate local instances are
/// unlikely to pick the same internal test listener.
int speedTestListenerPortFor(int mixedPort) {
  var port = 40000 + ((mixedPort.abs() * 37) % 8000);
  if (port == mixedPort) {
    port = port == 47999 ? 40000 : port + 1;
  }
  return port;
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
