import 'package:flutter/widgets.dart';

import 'lifecycle_controller.dart';
import 'lifecycle_event.dart';
import 'lifecycle_scope.dart';
import 'lifecycle_snapshot.dart';
import 'lifecycle_transition.dart';

/// Package-internal owner for a widget-level lifecycle node.
///
/// It centralizes controller creation, parent synchronization, callback
/// dispatch, scope construction, and disposal for lifecycle widgets and
/// mixins. It is intentionally not exported from the package library.
final class LifecycleNodeBinding {
  LifecycleNodeBinding({
    bool visible = true,
    bool active = true,
    double visibleFraction = 1,
    String? debugLabel,
    VoidCallback? onChanged,
  })  : _onChanged = onChanged,
        controller = LifecycleController(
          visible: visible,
          active: active,
          visibleFraction: visibleFraction,
          debugLabel: debugLabel,
        ) {
    if (onChanged != null) controller.addListener(onChanged);
  }

  final VoidCallback? _onChanged;
  final LifecycleController controller;

  LifecycleSnapshot get value => controller.value;

  LifecycleTransition? get lastTransition => controller.lastTransition;

  /// Attaches to the nearest effective parent, or reparents after dependencies
  /// change. [cause] is used only for the node's initial attachment, matching
  /// Flutter's widget dependency lifecycle.
  void syncParent(
    BuildContext context, {
    LifecycleCause cause = LifecycleCause.widgetTree,
  }) {
    final parent = resolveLifecycleParent(context);
    if (controller.isAttached) {
      controller.reparent(parent);
    } else {
      controller.attach(parent: parent, cause: cause);
    }
  }

  void update({
    bool? visible,
    bool? active,
    double? visibleFraction,
    LifecycleCause cause = LifecycleCause.custom,
  }) {
    controller.updateLocal(
      visible: visible,
      active: active,
      visibleFraction: visibleFraction,
      cause: cause,
    );
  }

  void dispatch({
    LifecycleTransitionCallback? onTransition,
    LifecycleEventCallback? onEvent,
  }) {
    final transition = lastTransition;
    if (transition == null) return;
    onTransition?.call(transition);
    if (onEvent != null) {
      for (final event in transition.events) {
        onEvent(event, transition);
      }
    }
  }

  Widget buildScope({
    required BuildContext context,
    required LifecycleScopeKind kind,
    required Widget child,
  }) {
    return LifecycleScope(
      controller: controller,
      kind: kind,
      route: ModalRoute.of(context),
      child: child,
    );
  }

  /// Disposes the controller, optionally delivering its terminal transition
  /// to the registered callback.
  void dispose({bool deliverTerminalTransition = true}) {
    final onChanged = _onChanged;
    if (!deliverTerminalTransition && onChanged != null) {
      controller.removeListener(onChanged);
    }
    controller.dispose();
  }
}
