import 'package:fl_clash/common/desktop_route.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop routes never rewrite each other', () {
    for (final state in const [
      (tun: false, systemProxy: false),
      (tun: true, systemProxy: false),
      (tun: false, systemProxy: true),
      (tun: true, systemProxy: true),
    ]) {
      expect(reconcileDesktopRoute(state), state);
      expect(reconcileDesktopRoute(state, changed: DesktopRoute.tun), state);
      expect(
        reconcileDesktopRoute(state, changed: DesktopRoute.systemProxy),
        state,
      );
    }
  });
}
