/*
 * 单条 Route 的私有生命周期记录。
 *
 * 每个 entry 持有稳定 Controller 身份，路由可见性变化只更新 Constraint，移除时使用
 * 明确 Cause 生成终止 Transition。entry 不公开，避免外部绕过 Navigator 历史直接
 * 修改路由节点。
 */
part of 'navigator_lifecycle_controller.dart';

/// 为 Route 保持稳定 Controller 身份的内部记录。
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
