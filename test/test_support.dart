/*
 * 框架 Widget 测试共享的应用壳、事件日志和探针组件。
 *
 * lifecycleTestApp 统一安装 App/Navigator Scope；LifecycleProbe 将 Event 收集为可断言
 * 序列；公共 matcher 描述常见 created/active/hidden 轨迹，减少测试间样板和顺序误写。
 */
import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

/// 按探针名称保存有序 Event，便于断言跨节点传播顺序。
class LifecycleEventLog {
  final Map<String, List<LifecycleEvent>> _events = {};
  final Map<String, List<LifecycleTransition>> _transitions = {};

  List<LifecycleEvent> operator [](String name) {
    return _events.putIfAbsent(name, () => []);
  }

  List<LifecycleTransition> transitions(String name) {
    return _transitions.putIfAbsent(name, () => []);
  }

  void add(String name, LifecycleEvent event) {
    this[name].add(event);
  }

  void addTransition(String name, LifecycleTransition transition) {
    transitions(name).add(transition);
  }

  void clear([String? name]) {
    if (name == null) {
      for (final events in _events.values) {
        events.clear();
      }
      for (final transitions in _transitions.values) {
        transitions.clear();
      }
    } else {
      this[name].clear();
      transitions(name).clear();
    }
  }
}

/// 在不改变 child 布局的情况下记录最近作用域的生命周期事件。
class LifecycleProbe extends StatelessWidget {
  const LifecycleProbe({
    super.key,
    required this.name,
    required this.log,
    this.child = const SizedBox.shrink(),
  });

  final String name;
  final LifecycleEventLog log;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LifecycleListener(
      onTransition: (transition) => log.addTransition(name, transition),
      onEvent: (event, _) => log.add(name, event),
      child: child,
    );
  }
}

Widget lifecycleTestApp({
  required Widget home,
  NavigatorLifecycleController? navigation,
  GlobalKey<NavigatorState>? navigatorKey,
}) {
  return LifecycleApp(
    child: MaterialApp(
      navigatorKey: navigatorKey,
      navigatorObservers: [if (navigation != null) navigation.observer],
      builder: navigation == null
          ? null
          : (context, child) =>
              NavigatorLifecycleScope(controller: navigation, child: child!),
      home: home,
    ),
  );
}

const createdAndActive = [
  LifecycleEvent.created,
  LifecycleEvent.appeared,
  LifecycleEvent.activated,
];

const hiddenFromActive = [
  LifecycleEvent.deactivated,
  LifecycleEvent.disappeared,
];

const disposedFromActive = [
  LifecycleEvent.deactivated,
  LifecycleEvent.disappeared,
  LifecycleEvent.disposed,
];
