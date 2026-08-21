/*
 * 声明生命周期阶段、语义事件、变化原因和回调签名。
 *
 * Phase 描述稳定快照，Event 描述两个快照之间的语义差异，Cause 描述变化来源；三者
 * 分离后，调用方既能按当前状态渲染，也能按边沿事件执行一次性副作用，避免把平台
 * AppLifecycleState、路由状态和 Widget 可见性混为同一枚举。
 */
/// The stable state represented by a lifecycle snapshot.
enum LifecyclePhase {
  /// The controller has not been attached to a lifecycle tree.
  detached,

  /// The node exists but is not currently visible.
  hidden,

  /// The node is visible but not the active interaction target.
  visible,

  /// The node is visible and is the active interaction target.
  active,

  /// The controller and its widget node have been disposed.
  disposed,
}

/// Semantic events derived from transitions between lifecycle phases.
enum LifecycleEvent {
  /// A controller was attached to the lifecycle tree.
  created,

  /// A hidden node became visible.
  appeared,

  /// A visible node became active.
  activated,

  /// An active node stopped being active.
  deactivated,

  /// A visible node became hidden.
  disappeared,

  /// The lifecycle node was permanently disposed.
  disposed,
}

/// The subsystem that initiated a lifecycle transition.
enum LifecycleCause {
  /// The Flutter application lifecycle changed.
  app,

  /// Navigator route history or opacity changed.
  route,

  /// An interactive Navigator gesture changed route exposure.
  routeGesture,

  /// PageView or TabBarView selection changed.
  pageSelection,

  /// Scrollable viewport geometry changed.
  viewport,

  /// A widget was attached, reparented, or disposed.
  widgetTree,

  /// An application-defined boundary or controller update changed.
  custom,
}
