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
