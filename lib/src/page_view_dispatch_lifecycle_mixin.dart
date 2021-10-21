import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';

/// Dispatch lifecycle event to child page.
mixin PageViewDispatchLifecycleMixin<T extends StatefulWidget>
    on State<T>, LifecycleAware {
  PageController? _pageController;

  /// Current page.
  int _curPage = 0;

  /// Map of page index and child.
  final Map<int, LifecycleAware> _lifecycleSubscribers = {};

  @override
  void initState() {
    super.initState();
    // visitChildElements() can't called during build, so we schedule a frame callback.
    SchedulerBinding.instance!.scheduleFrameCallback((_) {
      _updateController();
    });
  }

  @override
  void dispose() {
    _pageController?.removeListener(_onPageChanged);
    super.dispose();
  }

  void subscribe(int index, LifecycleAware lifecycleAware) {
    if (_lifecycleSubscribers[index] != lifecycleAware) {
      _lifecycleSubscribers[index] = lifecycleAware;
      // Dispatch [LifecycleEvent.active] to initial page.
      if (_curPage == index) {
        if (ModalRoute.of(context)!.isCurrent) {
          dispatchEvents(lifecycleEventsVisibleAndActive);
        } else {
          dispatchEvents([LifecycleEvent.visible]);
        }
      }
    }
  }

  void unsubscribe(LifecycleAware lifecycleAware) {
    if (_lifecycleSubscribers.containsValue(lifecycleAware)) {
      _lifecycleSubscribers
          .removeWhere((key, value) => value == lifecycleAware);
    }
  }

  @override
  void handleLifecycleEvents(List<LifecycleEvent> events) {
    super.handleLifecycleEvents(events);
    dispatchEvents(events);
  }

  /// Dispatch [events] to subscribers.
  void dispatchEvents(List<LifecycleEvent> events) {
    _lifecycleSubscribers[_curPage]?.handleLifecycleEvents(events);
  }

  void _updateController() {
    PageController? pageController;
    void findPageView(Element element) {
      if (element.widget is PageView) {
        PageView pageView = element.widget as PageView;
        pageController = pageView.controller;
        return;
      }
      element.visitChildren(findPageView);
    }

    context.visitChildElements(findPageView);
    if (pageController == null) {
      throw FlutterError('Child widget is not a PageView or TabBarView.');
    }

    PageController newValue = pageController!;
    if (_pageController == newValue) return;
    final ScrollController? oldValue = _pageController;
    _pageController = newValue;
    _curPage = _pageController!.page!.round();
    oldValue?.removeListener(_onPageChanged);
    newValue.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    if (_pageController!.page == null) return;
    int page = _pageController!.page!.round();
    if (_curPage == page) return;
    // print('PageController#onPageChanged: from page[$curPage]');
    dispatchEvents(lifecycleEventsInactiveAndInvisible);
    _curPage = page;
    // print('PageController#onPageChanged: to page[$curPage]');
    if (ModalRoute.of(context)?.isCurrent == true) {
      dispatchEvents(lifecycleEventsVisibleAndActive);
    } else {
      dispatchEvents([LifecycleEvent.visible]);
    }
  }
}
