import 'dart:io';

import 'package:fl_clash/common/update_recovery.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late UpdateRecoveryStore store;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('update-recovery-test-');
    store = UpdateRecoveryStore(homeDirectory: () async => tempDir.path);
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('round-trips once and then consumes the marker', () async {
    final now = DateTime.utc(2026, 10, 4, 10);
    final state = UpdateRecoveryState.now(
      running: true,
      systemProxy: true,
      tun: false,
      now: now,
    );

    await store.save(state);

    final restored = await store.take(now: now.add(const Duration(minutes: 1)));
    expect(restored, isNotNull);
    expect(restored!.running, isTrue);
    expect(restored.systemProxy, isTrue);
    expect(restored.tun, isFalse);
    expect(await store.take(now: now), isNull);
  });

  test('stale state is ignored and consumed', () async {
    final now = DateTime.utc(2026, 10, 4, 10);
    await store.save(
      UpdateRecoveryState.now(
        running: true,
        systemProxy: true,
        tun: true,
        now: now.subtract(const Duration(hours: 1)),
      ),
    );

    expect(await store.take(now: now), isNull);
    expect(await store.take(now: now), isNull);
  });

  test('applies connection switches without touching profile selection', () {
    const config = Config(
      themeProps: defaultThemeProps,
      networkProps: NetworkProps(systemProxy: false),
      patchClashConfig: PatchClashConfig(),
      currentProfileId: 99,
    );
    final state = UpdateRecoveryState.now(
      running: true,
      systemProxy: true,
      tun: true,
      now: DateTime.utc(2026),
    );

    final restored = applyUpdateRecoveryState(config, state);

    expect(restored.networkProps.systemProxy, isTrue);
    expect(restored.patchClashConfig.tun.enable, isTrue);
    expect(restored.currentProfileId, 99);
  });
}
