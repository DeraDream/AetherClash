enum DesktopRoute { tun, systemProxy }

typedef DesktopRouteState = ({bool tun, bool systemProxy});

/// Desktop TUN and the system proxy are independent controls.
///
/// Both enabled, both disabled, or either one enabled are all valid states.
/// [changed] is kept for call-site compatibility but never mutates the other
/// route.
DesktopRouteState reconcileDesktopRoute(
  DesktopRouteState state, {
  DesktopRoute? changed,
}) {
  return state;
}
