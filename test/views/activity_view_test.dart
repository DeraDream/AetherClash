import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/activity.dart';
import 'package:fl_clash/views/connection/connections.dart';
import 'package:fl_clash/views/logs.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [profilesProvider.overrideWith(TestProfiles.new)],
    );
    globalState.container = container;
    container
        .read(viewSizeProvider.notifier)
        .update((_) => const Size(1200, 900));
  });

  tearDown(() => container.dispose());

  Future<void> pumpActivity(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: ActivityView()),
      ),
    );
    await tester.pump();
  }

  Future<void> drainCorePoll(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 11));
  }

  testWidgets('the segmented switch keeps connections and optional logs only', (
    tester,
  ) async {
    await pumpActivity(tester);

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(GlassSegmented<PageLabel>),
      ),
      findsNothing,
      reason: 'a single Connections page must not render a segmented title pill',
    );
    expect(find.byType(ConnectionsView), findsOneWidget);
    expect(find.text('Logs'), findsNothing);

    expect(find.text('Requests'), findsNothing);
    expect(find.byType(ConnectionsView), findsOneWidget);

    await drainCorePoll(tester);
  });

  testWidgets('logs join the switch only when they are enabled', (
    tester,
  ) async {
    container
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(openLogs: true));
    await pumpActivity(tester);

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(GlassSegmented<PageLabel>),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Logs'));
    await tester.pump();
    expect(find.byType(LogsView), findsOneWidget);
    expect(find.byType(ConnectionsView), findsNothing);

    container
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(openLogs: false));
    await tester.pump();
    expect(find.text('Logs'), findsNothing);
    expect(find.byType(LogsView), findsNothing);
    expect(find.byType(ConnectionsView), findsOneWidget);

    await drainCorePoll(tester);
  });
}
