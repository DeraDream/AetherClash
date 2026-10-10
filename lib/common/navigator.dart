import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/widgets/glass.dart';
import 'package:material_ui/material_ui.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final Map<PageLabel, GlobalKey<NavigatorState>> _workspaceNavigatorKeys = {};
final Map<PageLabel, Set<String>> _workspaceRouteNames = {};

/// Stable nested navigator for each non-mobile workspace page.
GlobalKey<NavigatorState> workspaceNavigatorKey(PageLabel label) {
  return _workspaceNavigatorKeys.putIfAbsent(
    label,
    () => GlobalKey<NavigatorState>(
      debugLabel: '${label.name}_workspace_navigator',
    ),
  );
}

/// Android animates pages along with the predictive back gesture; the other
/// platforms use the fade-forwards transition it falls back to, with a clear
/// background so a page pushed inside a glass panel never flashes opaque.
const appPageTransitionsTheme = PageTransitionsTheme(
  builders: <TargetPlatform, PageTransitionsBuilder>{
    TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
    TargetPlatform.windows: _glassFadeForwards,
    TargetPlatform.linux: _glassFadeForwards,
    TargetPlatform.macOS: _glassFadeForwards,
  },
);

const _glassFadeForwards = FadeForwardsPageTransitionsBuilder(
  backgroundColor: Colors.transparent,
);

class BaseNavigator {
  /// A page pushed over the whole window brings its own floor; one pushed
  /// inside the workspace stays transparent over it.
  static Future<T?> push<T>(BuildContext context, Widget child) {
    final navigator = Navigator.of(context);
    final coversWindow =
        navigator == Navigator.of(context, rootNavigator: true);
    return navigator.push<T>(
      MaterialPageRoute<T>(
        builder: (_) => coversWindow ? AppFloor(child: child) : child,
      ),
    );
  }

  /// Pushes a page into the currently visible desktop/laptop workspace.
  ///
  /// This intentionally never falls back to the root navigator, so persistent
  /// shell chrome such as the left sidebar cannot be covered by mistake.
  static Future<T?> pushToWorkspace<T>(PageLabel label, Widget child) {
    final navigator = workspaceNavigatorKey(label).currentState;
    if (navigator == null) {
      return Future<T?>.value(null);
    }
    return navigator.push<T>(MaterialPageRoute<T>(builder: (_) => child));
  }

  /// Pushes a named page into a workspace only if that page is not already
  /// present in the workspace stack. This keeps persistent sidebar actions
  /// from stacking duplicate copies of the same settings page.
  static Future<T?> pushToWorkspaceOnce<T>(
    PageLabel label,
    String routeName,
    Widget child,
  ) {
    final activeRoutes = _workspaceRouteNames.putIfAbsent(
      label,
      () => <String>{},
    );
    if (!activeRoutes.add(routeName)) {
      return Future<T?>.value(null);
    }

    final navigator = workspaceNavigatorKey(label).currentState;
    if (navigator == null) {
      activeRoutes.remove(routeName);
      return Future<T?>.value(null);
    }

    return navigator
        .push<T>(
          MaterialPageRoute<T>(
            settings: RouteSettings(name: routeName),
            builder: (_) => child,
          ),
        )
        .whenComplete(() => activeRoutes.remove(routeName));
  }
}
