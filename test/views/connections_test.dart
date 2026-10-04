import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/database.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/connection/connections.dart';
import 'package:fl_clash/widgets/null_status.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

class MockCoreHandlerInterface extends Mock implements CoreHandlerInterface {}

TrackerInfo _tracker({
  required String id,
  String host = 'example.com',
  String process = 'curl',
  List<String> chains = const ['Proxy'],
  int upload = 0,
  int download = 0,
  DateTime? start,
}) {
  return TrackerInfo(
    id: id,
    upload: upload,
    download: download,
    start: start ?? DateTime.utc(2026),
    metadata: Metadata(
      network: 'tcp',
      host: host,
      destinationIP: '1.1.1.1',
      destinationPort: '443',
      process: process,
    ),
    chains: chains,
    rule: 'DOMAIN',
    rulePayload: host,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCoreHandlerInterface core;
  late ProviderContainer container;

  setUpAll(() {
    core = MockCoreHandlerInterface();
    CoreController.resetInstance();
    CoreController.test(core);
  });

  tearDownAll(CoreController.resetInstance);

  setUp(() {
    reset(core);
    container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    globalState.container = container;
  });

  tearDown(() => container.dispose());

  Future<void> pumpConnections(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: ConnectionsView()),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  Future<void> teardownView(WidgetTester tester) async {
    final filter = find.byKey(const Key('connections-filter'));
    if (filter.evaluate().isNotEmpty) {
      await tester.enterText(filter, '');
      await tester.pump();
    }
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
  }

  testWidgets('shows the empty state when core reports no connections', (
    tester,
  ) async {
    when(core.getConnections).thenAnswer((_) async => const <TrackerInfo>[]);

    await pumpConnections(tester);

    expect(find.byType(NullStatus), findsOneWidget);
    expect(tester.takeException(), null);

    await teardownView(tester);
  });

  testWidgets('renders one row per reported connection', (tester) async {
    when(core.getConnections).thenAnswer(
      (_) async => [
        _tracker(id: 'a', host: 'alpha.test'),
        _tracker(id: 'b', host: 'beta.test'),
      ],
    );

    await pumpConnections(tester);
    await tester.pump(commonDuration);
    await tester.pump(commonDuration);

    expect(find.byType(NullStatus), findsNothing);
    expect(find.textContaining('alpha.test'), findsWidgets);
    expect(find.textContaining('beta.test'), findsWidgets);
    expect(tester.takeException(), null);

    await teardownView(tester);
  });

  testWidgets('moves vanished connections into the closed tab', (
    tester,
  ) async {
    var call = 0;
    when(core.getConnections).thenAnswer((_) async {
      call++;
      if (call == 1) {
        return [_tracker(id: 'a', host: 'alpha.test', download: 100)];
      }
      return const <TrackerInfo>[];
    });

    await pumpConnections(tester);
    expect(find.textContaining('alpha.test'), findsWidgets);

    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    await tester.tap(find.textContaining('Closed'));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.textContaining('alpha.test'), findsWidgets);

    await teardownView(tester);
  });

  testWidgets('search matches fields beyond host and process', (tester) async {
    when(core.getConnections).thenAnswer(
      (_) async => [
        TrackerInfo(
          id: 'needle-id',
          start: DateTime.utc(2026),
          metadata: const Metadata(
            network: 'tcp',
            host: 'alpha.test',
            sourceIP: '10.0.0.8',
            sourcePort: '53123',
            destinationIP: '8.8.8.8',
            destinationPort: '443',
            process: 'chrome.exe',
            processPath: r'C:\\Browser\\chrome.exe',
          ),
          chains: const ['Proxy-A'],
          rule: 'DOMAIN-SUFFIX',
          rulePayload: 'example.org',
        ),
      ],
    );

    await pumpConnections(tester);

    final field = find.byKey(const Key('connections-filter'));
    await tester.enterText(field, '53123');
    await tester.pump();
    expect(find.textContaining('alpha.test'), findsWidgets);

    await tester.enterText(field, 'example.org');
    await tester.pump();
    expect(find.textContaining('alpha.test'), findsWidgets);

    await teardownView(tester);
  });

  testWidgets('keeps search open while realtime snapshots refresh', (
    tester,
  ) async {
    var download = 0;
    when(core.getConnections).thenAnswer(
      (_) async => [
        _tracker(
          id: 'a',
          host: 'alpha.test',
          download: download += 128,
        ),
      ],
    );

    await pumpConnections(tester);
    final field = find.byKey(const Key('connections-filter'));
    await tester.enterText(field, 'alpha');

    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump();

    expect(field, findsOneWidget);
    expect(
      tester.widget<TextField>(field).controller?.text,
      'alpha',
    );
    expect(find.textContaining('alpha.test'), findsWidgets);

    await teardownView(tester);
  });

  testWidgets('table column sort starts descending then toggles ascending', (
    tester,
  ) async {
    var tick = 0;
    when(core.getConnections).thenAnswer((_) async {
      tick++;
      return [
        _tracker(
          id: 'slow',
          host: 'slow.test',
          download: tick * 100,
        ),
        _tracker(
          id: 'fast',
          host: 'fast.test',
          download: tick * 1000,
        ),
      ];
    });

    await pumpConnections(tester);
    await tester.pump(const Duration(milliseconds: 550));
    await tester.pump();

    final header = find.byKey(
      const Key('connection-header-downloadSpeed'),
    );
    await tester.tap(header);
    await tester.pump();

    final fastRow = find.byKey(const Key('connection-row-fast'));
    final slowRow = find.byKey(const Key('connection-row-slow'));
    expect(tester.getTopLeft(fastRow).dy, lessThan(tester.getTopLeft(slowRow).dy));
    expect(find.textContaining('Download speed ↓'), findsOneWidget);

    await tester.tap(header);
    await tester.pump();

    expect(tester.getTopLeft(fastRow).dy, greaterThan(tester.getTopLeft(slowRow).dy));
    expect(find.textContaining('Download speed ↑'), findsOneWidget);

    await teardownView(tester);
  });

  testWidgets('pause stops snapshots and resume restarts immediately', (
    tester,
  ) async {
    var calls = 0;
    when(core.getConnections).thenAnswer((_) async {
      calls++;
      return [
        _tracker(
          id: 'a',
          host: 'alpha.test',
          download: calls * 128,
        ),
      ];
    });

    await pumpConnections(tester);

    final pause = find.byKey(const Key('connections-pause'));
    await tester.tap(pause);
    await tester.pump();
    final pausedCalls = calls;

    await tester.pump(const Duration(milliseconds: 1200));
    expect(calls, pausedCalls);

    await tester.tap(pause);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(calls, greaterThan(pausedCalls));

    await teardownView(tester);
  });

  testWidgets('keeps the empty state when core throws', (tester) async {
    when(core.getConnections).thenThrow(StateError('core down'));

    await pumpConnections(tester);

    expect(find.byType(NullStatus), findsOneWidget);
    expect(tester.takeException(), null);

    await teardownView(tester);
  });

  testWidgets('stops polling once the view is disposed', (tester) async {
    when(core.getConnections).thenAnswer((_) async => const <TrackerInfo>[]);

    await pumpConnections(tester);
    await teardownView(tester);
    clearInteractions(core);

    await tester.pump(const Duration(seconds: 3));

    verifyNever(core.getConnections);
  });
}
