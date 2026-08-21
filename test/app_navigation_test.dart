/*
 * App 根节点与 Navigator 路由生命周期的 Widget 回归测试。
 *
 * 覆盖 opaque/非 opaque 路由、替换移除、Navigator 2.0、嵌套 Navigator、Controller
 * 替换和 Boundary/Mixin 消费方式，验证路由历史、遮挡规则及 App 状态能组合成一致事件。
 */
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifecycle/lifecycle.dart';

import 'test_support.dart';

void main() {
  group('widget lifecycle APIs', () {
    // 验证 LifecycleApp 将 resumed、inactive、hidden 等应用状态映射为确定的事件和原因。
    testWidgets('LifecycleApp maps app states into deterministic events', (
      tester,
    ) async {
      final log = LifecycleEventLog();
      final causes = <LifecycleCause>[];

      await tester.pumpWidget(
        LifecycleApp(
          child: LifecycleListener(
            onTransition: (transition) => causes.add(transition.cause),
            onEvent: (event, _) => log.add('app', event),
            child: const SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();

      expect(log['app'], createdAndActive);
      expect(causes, everyElement(LifecycleCause.widgetTree));
      log.clear();
      causes.clear();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump();

      expect(log['app'], [
        LifecycleEvent.deactivated,
        LifecycleEvent.disappeared,
      ]);
      expect(causes, everyElement(LifecycleCause.app));
      log.clear();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(log['app'], [LifecycleEvent.appeared, LifecycleEvent.activated]);
    });

    // 验证自定义 Boundary 会限制后代状态，并驱动 LifecycleBuilder 显示最新 phase。
    testWidgets(
      'LifecycleBoundary composes state and LifecycleBuilder rebuilds',
      (tester) async {
        final log = LifecycleEventLog();
        final fixtureKey = GlobalKey<_BoundaryFixtureState>();

        await tester.pumpWidget(
          LifecycleApp(
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: _BoundaryFixture(key: fixtureKey, log: log),
            ),
          ),
        );
        await tester.pump();

        expect(log['boundary'], [LifecycleEvent.created]);
        expect(log['child'], [LifecycleEvent.created]);
        expect(find.text('hidden'), findsOneWidget);
        log.clear();

        fixtureKey.currentState!.show();
        await tester.pump();

        expect(log['boundary'], [
          LifecycleEvent.appeared,
          LifecycleEvent.activated,
        ]);
        expect(log['child'], [
          LifecycleEvent.appeared,
          LifecycleEvent.activated,
        ]);
        expect(find.text('active'), findsOneWidget);
        log.clear();

        fixtureKey.currentState!.setInactive();
        await tester.pump();
        expect(log['boundary'], [LifecycleEvent.deactivated]);
        expect(log['child'], [LifecycleEvent.deactivated]);
        expect(find.text('visible'), findsOneWidget);
      },
    );

    // 验证 LifecycleStateMixin 在 State 挂载和移除时收到完整的创建与销毁事件。
    testWidgets('LifecycleStateMixin receives creation and disposal events', (
      tester,
    ) async {
      final log = LifecycleEventLog();

      await tester.pumpWidget(LifecycleApp(child: _MixinProbe(log: log)));
      await tester.pump();
      expect(log['mixin'], createdAndActive);

      log.clear();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(log['mixin'], disposedFromActive);
      expect(
        log.transitions('mixin').last.current.appState,
        AppLifecycleState.resumed,
      );
    });

    // 验证 LifecycleListener 从 Widget 树移除时会收到最终 disposed 事件序列。
    testWidgets('LifecycleListener emits disposed when removed', (
      tester,
    ) async {
      final log = LifecycleEventLog();

      await tester.pumpWidget(
        LifecycleApp(
          child: LifecycleProbe(name: 'listener', log: log),
        ),
      );
      await tester.pump();
      log.clear();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(log['listener'], disposedFromActive);
      final terminal = log.transitions('listener').last;
      expect(terminal.current.phase, LifecyclePhase.disposed);
      expect(terminal.current.appState, AppLifecycleState.resumed);
    });

    // 验证 LifecycleApp 可使用外部 controller，并在热替换 controller 后正确迁移子节点状态。
    testWidgets('LifecycleApp supports an external controller and hot swap', (
      tester,
    ) async {
      final external = AppLifecycleController(debugLabel: 'external');
      addTearDown(external.dispose);
      final log = LifecycleEventLog();
      LifecycleController? capturedController;

      Widget child() => Builder(
            builder: (context) {
              capturedController = LifecycleScope.of(context);
              return LifecycleProbe(name: 'swap', log: log);
            },
          );

      await tester.pumpWidget(LifecycleApp(child: child()));
      await tester.pump();
      expect(capturedController, isA<AppLifecycleController>());
      log.clear();

      await tester.pumpWidget(
        LifecycleApp(controller: external, child: child()),
      );
      await tester.pump();

      expect(capturedController, same(external));
      expect(log['swap'], [
        LifecycleEvent.deactivated,
        LifecycleEvent.disappeared,
        LifecycleEvent.appeared,
        LifecycleEvent.activated,
      ]);
    });

    // 验证 paused 和 detached 都映射为 hidden，同时保留最近的原始 AppLifecycleState。
    testWidgets('AppLifecycleController maps paused and detached states', (
      tester,
    ) async {
      final controller = AppLifecycleController();
      addTearDown(controller.dispose);

      expect(controller.appState, AppLifecycleState.resumed);
      controller.didChangeAppLifecycleState(AppLifecycleState.paused);
      expect(controller.value.phase, LifecyclePhase.hidden);
      expect(controller.appState, AppLifecycleState.paused);

      controller.didChangeAppLifecycleState(AppLifecycleState.detached);
      expect(controller.appState, AppLifecycleState.detached);
    });

    // 验证 NavigatorLifecycleScope 更换 controller 时旧树隐藏、新树接管当前 Route。
    testWidgets('NavigatorLifecycleScope migrates between controllers', (
      tester,
    ) async {
      final first = NavigatorLifecycleController();
      final second = NavigatorLifecycleController();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      final fixtureKey = GlobalKey<_NavigationScopeSwapFixtureState>();

      await tester.pumpWidget(
        LifecycleApp(
          child: _NavigationScopeSwapFixture(
            key: fixtureKey,
            first: first,
            second: second,
          ),
        ),
      );
      await tester.pump();
      expect(first.lifecycle.phase, LifecyclePhase.active);

      fixtureKey.currentState!.swap();
      await tester.pump();
      expect(first.lifecycle.phase, LifecyclePhase.hidden);
      expect(second.lifecycle.phase, LifecyclePhase.active);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(second.lifecycle.phase, LifecyclePhase.hidden);
    });
  });

  group('Navigator lifecycle', () {
    // 验证压入不透明页面会隐藏旧页面，弹出后旧页面按 appeared、activated 顺序恢复。
    testWidgets('dispatches opaque page push and pop', (tester) async {
      final navigation = _testNavigation();
      final navigatorKey = GlobalKey<NavigatorState>();
      final log = LifecycleEventLog();

      await tester.pumpWidget(
        lifecycleTestApp(
          navigation: navigation,
          navigatorKey: navigatorKey,
          home: _LifecyclePage(name: 'home', log: log),
        ),
      );
      await tester.pumpAndSettle();
      expect(log['home'], createdAndActive);
      log.clear();

      navigatorKey.currentState!.push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/details'),
          builder: (_) => _LifecyclePage(name: 'details', log: log),
        ),
      );
      await tester.pumpAndSettle();

      expect(log['home'], hiddenFromActive);
      expect(log['details'], createdAndActive);
      expect(navigation.routeNamed('/details'), isNotNull);
      log.clear();

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(log['details'], disposedFromActive);
      expect(log['home'], [LifecycleEvent.appeared, LifecycleEvent.activated]);
    });

    // 验证非透明 Dialog 只让下层页面失活而不消失，关闭 Dialog 后页面重新激活。
    testWidgets('keeps the page visible but inactive behind a dialog', (
      tester,
    ) async {
      final navigation = _testNavigation();
      final navigatorKey = GlobalKey<NavigatorState>();
      final log = LifecycleEventLog();

      await tester.pumpWidget(
        lifecycleTestApp(
          navigation: navigation,
          navigatorKey: navigatorKey,
          home: _LifecyclePage(name: 'home', log: log),
        ),
      );
      await tester.pumpAndSettle();
      log.clear();

      showDialog<void>(
        context: navigatorKey.currentContext!,
        routeSettings: const RouteSettings(name: '/dialog'),
        builder: (_) => LifecycleProbe(
          name: 'dialog',
          log: log,
          child: const AlertDialog(content: Text('Dialog')),
        ),
      );
      await tester.pumpAndSettle();

      expect(log['home'], [LifecycleEvent.deactivated]);
      expect(log['dialog'], createdAndActive);
      expect(navigation.routes.length, 2);
      log.clear();

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();

      expect(log['dialog'], disposedFromActive);
      final dialogTerminal = log.transitions('dialog').last;
      expect(dialogTerminal.previous.appState, AppLifecycleState.resumed);
      expect(dialogTerminal.current.appState, AppLifecycleState.resumed);
      expect(log['home'], [LifecycleEvent.activated]);
    });

    // 验证 Route replacement、按名称查询和 removeRoute 返回结果均与生命周期历史同步。
    testWidgets('supports replacement and removeRoute results', (tester) async {
      final navigation = _testNavigation();
      final navigatorKey = GlobalKey<NavigatorState>();
      final log = LifecycleEventLog();

      await tester.pumpWidget(
        lifecycleTestApp(
          navigation: navigation,
          navigatorKey: navigatorKey,
          home: _LifecyclePage(name: 'home', log: log),
        ),
      );
      await tester.pumpAndSettle();

      navigatorKey.currentState!.push<void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/first'),
          builder: (_) => _LifecyclePage(name: 'first', log: log),
        ),
      );
      await tester.pumpAndSettle();
      log.clear();

      navigatorKey.currentState!.pushReplacement<void, void>(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/replacement'),
          builder: (_) => _LifecyclePage(name: 'replacement', log: log),
        ),
      );
      await tester.pumpAndSettle();

      expect(log['first'], disposedFromActive);
      expect(log['replacement'], createdAndActive);

      final resultRoute = MaterialPageRoute<String>(
        settings: const RouteSettings(name: '/result'),
        builder: (_) => _LifecyclePage(name: 'result', log: log),
      );
      final resultFuture = navigatorKey.currentState!.push<String>(resultRoute);
      await tester.pumpAndSettle();

      navigation.removeRoute<String>(resultRoute, 'completed');
      await tester.pumpAndSettle();

      expect(await resultFuture, 'completed');
      expect(log['result'], [...createdAndActive, ...disposedFromActive]);
      expect(navigation.routeNamed('/result'), isNull);
    });

    // 验证交互式返回手势期间前一 Route 临时可见，手势取消后再次隐藏。
    testWidgets('exposes the previous route during a back gesture', (
      tester,
    ) async {
      final navigation = _testNavigation();
      final navigatorKey = GlobalKey<NavigatorState>();
      final log = LifecycleEventLog();

      await tester.pumpWidget(
        lifecycleTestApp(
          navigation: navigation,
          navigatorKey: navigatorKey,
          home: _LifecyclePage(name: 'home', log: log),
        ),
      );
      await tester.pumpAndSettle();

      final currentRoute = MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/current'),
        builder: (_) => _LifecyclePage(name: 'current', log: log),
      );
      navigatorKey.currentState!.push<void>(currentRoute);
      await tester.pumpAndSettle();
      final previousRoute = navigation.routes.first;
      log.clear();

      navigation.observer.didStartUserGesture(currentRoute, previousRoute);
      await tester.pump();
      expect(log['home'], [LifecycleEvent.appeared]);
      expect(log['current'], isEmpty);
      log.clear();

      navigation.observer.didStopUserGesture();
      await tester.pump();
      expect(log['home'], [LifecycleEvent.disappeared]);
    });

    // 验证嵌套 Navigator 的 Route 绑定各自 controller，不会污染外层路由历史。
    testWidgets('associates nested Navigators with their own controllers', (
      tester,
    ) async {
      final rootNavigation = _testNavigation();
      final nestedNavigation = _testNavigation();
      final log = LifecycleEventLog();

      await tester.pumpWidget(
        lifecycleTestApp(
          navigation: rootNavigation,
          home: NavigatorLifecycleScope(
            controller: nestedNavigation,
            child: Navigator(
              observers: [nestedNavigation.observer],
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/nested'),
                builder: (_) => _LifecyclePage(name: 'nested', log: log),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(log['nested'], createdAndActive);
      expect(rootNavigation.routes.length, 1);
      expect(nestedNavigation.routeNamed('/nested'), isNotNull);
    });

    // 验证声明式 Navigator.pages 增删页面时，Route 生命周期创建、覆盖和销毁保持正确。
    testWidgets('supports Navigator pages additions and removals', (
      tester,
    ) async {
      final navigation = _testNavigation();
      final log = LifecycleEventLog();
      final pagesKey = GlobalKey<_PagesFixtureState>();

      await tester.pumpWidget(
        LifecycleApp(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: _PagesFixture(
              key: pagesKey,
              navigation: navigation,
              log: log,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(log['page1'], createdAndActive);
      log.clear();

      pagesKey.currentState!.showSecond();
      await tester.pumpAndSettle();
      expect(log['page1'], hiddenFromActive);
      expect(log['page2'], createdAndActive);
      log.clear();

      pagesKey.currentState!.hideSecond();
      await tester.pumpAndSettle();
      expect(log['page2'], disposedFromActive);
      expect(log['page1'], [LifecycleEvent.appeared, LifecycleEvent.activated]);
    });
  });
}

NavigatorLifecycleController _testNavigation() {
  final controller = NavigatorLifecycleController();
  addTearDown(controller.dispose);
  return controller;
}

/// 在两个 Navigator Controller 之间切换，验证旧 Scope 会正确 detach。
class _NavigationScopeSwapFixture extends StatefulWidget {
  const _NavigationScopeSwapFixture({
    super.key,
    required this.first,
    required this.second,
  });

  final NavigatorLifecycleController first;
  final NavigatorLifecycleController second;

  @override
  State<_NavigationScopeSwapFixture> createState() =>
      _NavigationScopeSwapFixtureState();
}

class _NavigationScopeSwapFixtureState
    extends State<_NavigationScopeSwapFixture> {
  bool _useSecond = false;

  void swap() => setState(() => _useSecond = true);

  @override
  Widget build(BuildContext context) {
    return NavigatorLifecycleScope(
      controller: _useSecond ? widget.second : widget.first,
      child: const SizedBox.shrink(),
    );
  }
}

/// 路由测试中统一安装 Probe 的最小页面。
class _LifecyclePage extends StatelessWidget {
  const _LifecyclePage({required this.name, required this.log});

  final String name;
  final LifecycleEventLog log;

  @override
  Widget build(BuildContext context) {
    return LifecycleProbe(
      name: name,
      log: log,
      child: Scaffold(body: Text(name)),
    );
  }
}

/// 通过外部方法切换 Boundary 约束的测试夹具。
class _BoundaryFixture extends StatefulWidget {
  const _BoundaryFixture({super.key, required this.log});

  final LifecycleEventLog log;

  @override
  State<_BoundaryFixture> createState() => _BoundaryFixtureState();
}

class _BoundaryFixtureState extends State<_BoundaryFixture> {
  bool visible = false;
  bool active = false;

  void show() => setState(() {
        visible = true;
        active = true;
      });

  void setInactive() => setState(() => active = false);

  @override
  Widget build(BuildContext context) {
    return LifecycleBoundary(
      constraint: !visible
          ? const LifecycleConstraint.hidden()
          : active
              ? const LifecycleConstraint.active()
              : const LifecycleConstraint.visible(),
      onEvent: (event, _) => widget.log.add('boundary', event),
      child: LifecycleProbe(
        name: 'child',
        log: widget.log,
        child: LifecycleBuilder(
          builder: (context, lifecycle) => Text(lifecycle.phase.name),
        ),
      ),
    );
  }
}

/// 收集 LifecycleStateMixin 回调的测试组件。
class _MixinProbe extends StatefulWidget {
  const _MixinProbe({required this.log});

  final LifecycleEventLog log;

  @override
  State<_MixinProbe> createState() => _MixinProbeState();
}

class _MixinProbeState extends State<_MixinProbe> with LifecycleStateMixin {
  @override
  void onLifecycleTransition(LifecycleTransition transition) {
    widget.log.addTransition('mixin', transition);
  }

  @override
  void onLifecycleEvent(LifecycleEvent event, LifecycleTransition transition) {
    widget.log.add('mixin', event);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// 通过 Navigator.pages 动态增删声明式路由的夹具。
class _PagesFixture extends StatefulWidget {
  const _PagesFixture({super.key, required this.navigation, required this.log});

  final NavigatorLifecycleController navigation;
  final LifecycleEventLog log;

  @override
  State<_PagesFixture> createState() => _PagesFixtureState();
}

class _PagesFixtureState extends State<_PagesFixture> {
  bool _showSecond = false;

  void showSecond() => setState(() => _showSecond = true);

  void hideSecond() => setState(() => _showSecond = false);

  @override
  Widget build(BuildContext context) {
    return NavigatorLifecycleScope(
      controller: widget.navigation,
      child: Navigator(
        observers: [widget.navigation.observer],
        pages: [
          MaterialPage<void>(
            key: const ValueKey('page1'),
            name: '/page1',
            child: _LifecyclePage(name: 'page1', log: widget.log),
          ),
          if (_showSecond)
            MaterialPage<void>(
              key: const ValueKey('page2'),
              name: '/page2',
              child: _LifecyclePage(name: 'page2', log: widget.log),
            ),
        ],
        onDidRemovePage: (page) {
          if (page.name == '/page2' && _showSecond) {
            hideSecond();
          }
        },
      ),
    );
  }
}
