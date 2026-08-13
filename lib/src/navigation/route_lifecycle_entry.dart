import 'package:flutter/widgets.dart';

import '../core/lifecycle_controller.dart';
import '../core/lifecycle_event.dart';
import '../core/lifecycle_snapshot.dart';

/// A tracked Navigator route and its effective lifecycle controller.
class RouteLifecycleEntry {
  /// Creates a hidden route entry attached to [parent].
  RouteLifecycleEntry({
    required this.route,
    required LifecycleController parent,
  }) : controller = LifecycleController(
          visible: false,
          active: false,
          visibleFraction: 0,
          debugLabel: 'Route(${route.settings.name ?? route.hashCode})',
        )..attach(parent: parent, cause: LifecycleCause.route);

  /// Route tracked by this entry.
  final Route<dynamic> route;

  /// Controller containing the route's current lifecycle.
  final LifecycleController controller;

  /// Latest route lifecycle snapshot.
  LifecycleSnapshot get lifecycle => controller.value;

  /// Updates route visibility and activity.
  void update({
    required bool visible,
    required bool active,
    LifecycleCause cause = LifecycleCause.route,
  }) {
    controller.updateLocal(
      visible: visible,
      active: active,
      visibleFraction: visible ? 1 : 0,
      cause: cause,
    );
  }

  /// Disposes the route lifecycle using [cause].
  void dispose({LifecycleCause cause = LifecycleCause.route}) {
    controller.disposeWithCause(cause);
  }
}
