/*
 * lifecycle 包的唯一公开入口。
 *
 * 该文件只负责汇总稳定 API，不承载运行逻辑；具体实现按 app、core、navigation、
 * page、viewport 和 widgets 分层。集中导出可以避免用户依赖内部 binding、resolver
 * 或 route entry，从而为后续重构保留空间。
 */
/// Composable app, route, page, viewport, and widget lifecycle for Flutter.
library;

export 'src/app/app_lifecycle_controller.dart';
export 'src/app/lifecycle_app.dart';
export 'src/core/lifecycle_constraint.dart';
export 'src/core/lifecycle_controller.dart';
export 'src/core/lifecycle_event.dart';
export 'src/core/lifecycle_scope.dart' show LifecycleScope;
export 'src/core/lifecycle_snapshot.dart';
export 'src/core/lifecycle_transition.dart';
export 'src/navigation/navigator_lifecycle_controller.dart';
export 'src/page/indexed_lifecycle_scope.dart'
    show IndexedLifecycleTransitionCallback;
export 'src/page/lifecycle_page_view.dart';
export 'src/page/lifecycle_tab_bar_view.dart';
export 'src/viewport/viewport_lifecycle_item.dart';
export 'src/widgets/lifecycle_boundary.dart';
export 'src/widgets/lifecycle_listener.dart';
export 'src/widgets/lifecycle_state_mixin.dart';
