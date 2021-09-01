import 'package:flutter/material.dart';

import 'lifecycle_aware.dart';
import 'lifecycle_mixin.dart';
import 'parent_page_dispatch_lifecycle_mixin.dart';

/// Lifecycle wrapper for [PageView] / [TabBarView].
class ParentPageLifecycleWrapper extends StatefulWidget {
  /// Instance of [PageController] or [TabController].
  final ChangeNotifier controller;
  final OnLifecycleEvent? onLifecycleEvent;
  final Widget child;

  ParentPageLifecycleWrapper({
    Key? key,
    required this.controller,
    this.onLifecycleEvent,
    required this.child,
  })  : assert(controller is PageController || controller is TabController),
        super(key: key);

  @override
  ParentPageLifecycleWrapperState createState() {
    if (controller is PageController) {
      return _PageViewLifecycleWrapperState();
    } else if (controller is TabController) {
      return _TabBarViewLifecycleWrapperState();
    } else {
      throw ArgumentError.value(
          controller, 'controller', 'Illegal controller type');
    }
  }

  static ParentPageLifecycleWrapperState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ParentPageLifecycleWrapperState>();
  }
}

abstract class ParentPageLifecycleWrapperState
    extends State<ParentPageLifecycleWrapper>
    with LifecycleAware, LifecycleMixin, ParentPageDispatchLifecycleMixin {
  void onPageChanged();

  @override
  void initState() {
    super.initState();
    // log('ParentPageLifecycleWrapperState($hashCode)#initState');
    widget.controller.addListener(onPageChanged);
  }

  @override
  void dispose() {
    // log('ParentPageLifecycleWrapperState($hashCode)#dispose');
    widget.controller.removeListener(onPageChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    // log('ParentPageLifecycleWrapperState($hashCode)#${event.toString()}');
    widget.onLifecycleEvent?.call(event);
  }
}

class _PageViewLifecycleWrapperState extends ParentPageLifecycleWrapperState {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = widget.controller as PageController;
    curPage = _pageController.initialPage;
  }

  @override
  void onPageChanged() {
    if (_pageController.page == null) return;
    int page = _pageController.page!.round();
    if (curPage == page) return;
    // log('PageController#onPageChanged: from page[$curPage]');
    dispatchEvents(lifecycle_events_inactive_and_invisible);
    curPage = page;
    // log('PageController#onPageChanged: to page[$curPage]');
    if (ModalRoute.of(context)?.isCurrent == true) {
      dispatchEvents(lifecycle_events_visible_and_active);
    } else {
      dispatchEvents([LifecycleEvent.visible]);
    }
  }
}

class _TabBarViewLifecycleWrapperState extends ParentPageLifecycleWrapperState {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = widget.controller as TabController;
    curPage = _tabController.index;
  }

  @override
  void onPageChanged() {
    if (_tabController.indexIsChanging) return;
    int page = _tabController.index;
    if (curPage == page) return;
    // log('TabController#onPageChanged: from page[$curPage]');
    dispatchEvents(lifecycle_events_inactive_and_invisible);
    curPage = page;
    // log('TabController#onPageChanged: to page[$curPage]');
    if (ModalRoute.of(context)?.isCurrent == true) {
      dispatchEvents(lifecycle_events_visible_and_active);
    } else {
      dispatchEvents([LifecycleEvent.visible]);
    }
  }
}
