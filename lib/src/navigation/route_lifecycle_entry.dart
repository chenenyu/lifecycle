part of 'navigator_lifecycle_controller.dart';

class _RouteLifecycleEntry {
  _RouteLifecycleEntry({
    required this.route,
    required LifecycleController parent,
  }) : controller = LifecycleController(
          constraint: const LifecycleConstraint.hidden(),
          debugLabel: 'Route(${route.settings.name ?? route.hashCode})',
        )..attach(parent: parent, cause: LifecycleCause.route);

  final Route<dynamic> route;
  final LifecycleController controller;

  LifecycleSnapshot get lifecycle => controller.value;

  void update({
    required LifecycleConstraint constraint,
    LifecycleCause cause = LifecycleCause.route,
  }) {
    controller.updateLocal(
      constraint: constraint,
      cause: cause,
    );
  }

  void dispose({LifecycleCause cause = LifecycleCause.route}) {
    controller.disposeWithCause(cause);
  }
}
