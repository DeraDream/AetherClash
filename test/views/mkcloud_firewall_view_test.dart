import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/mkcloud_firewall.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/views/mkcloud_firewall.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

class _FakeMkcloudFirewall extends MkcloudFirewall {
  _FakeMkcloudFirewall(this.initial);

  final MkcloudFirewallState initial;

  @override
  MkcloudFirewallState build() => initial;
}

const _setting = MkcloudFirewallProps(
  apiUrl: 'https://user.example/mkcloud',
  apiKey: 'test-key',
);

Future<void> _pump(
  WidgetTester tester, {
  required MkcloudFirewallState state,
}) async {
  const size = Size(1200, 900);
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      mkcloudFirewallSettingProvider.overrideWithBuild((_, _) => _setting),
      mkcloudFirewallProvider.overrideWith(() => _FakeMkcloudFirewall(state)),
    ],
  );
  addTearDown(container.dispose);
  globalState.container = container;
  container.read(viewSizeProvider.notifier).update((_) => size);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const TestApp(child: MkcloudFirewallView()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows a local progress ring while an MKCloud request runs', (
    tester,
  ) async {
    await _pump(tester, state: const MkcloudFirewallState(isRunning: true));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(CommonCircleLoading), findsNothing);
  });

  testWidgets('requires a runtime endpoint instead of displaying a fixed URL', (
    tester,
  ) async {
    await _pump(tester, state: const MkcloudFirewallState());

    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.textContaining('www.mkcloud.net'), findsNothing);
    expect(find.text('https://user.example/mkcloud'), findsOneWidget);
  });
}
