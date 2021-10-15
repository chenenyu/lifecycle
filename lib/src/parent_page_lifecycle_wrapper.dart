import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'lifecycle_aware.dart';
import 'lifecycle_mixin.dart';
import 'parent_page_dispatch_lifecycle_mixin.dart';

/// Lifecycle wrapper for [PageView] / [TabBarView].
class ParentPageLifecycleWrapper extends StatefulWidget {
  final OnLifecycleEvent? onLifecycleEvent;
  final Widget child;

  const ParentPageLifecycleWrapper({
    Key? key,
    this.onLifecycleEvent,
    required this.child,
  }) : super(key: key);

  @override
  ParentPageLifecycleWrapperState createState() {
    return ParentPageLifecycleWrapperState();
  }

  static ParentPageLifecycleWrapperState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<ParentPageLifecycleWrapperState>();
  }
}

class ParentPageLifecycleWrapperState extends State<ParentPageLifecycleWrapper>
    with LifecycleAware, LifecycleMixin, ParentPageDispatchLifecycleMixin {
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    // log('ParentPageLifecycleWrapperState($hashCode)#initState');
    SchedulerBinding.instance!.endOfFrame.then((value) {
      _updateController();
    });
  }

  @override
  void dispose() {
    // log('ParentPageLifecycleWrapperState($hashCode)#dispose');
    _pageController?.removeListener(_onPageChanged);
    super.dispose();
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
    curPage = _pageController!.page!.round();
    oldValue?.removeListener(_onPageChanged);
    newValue.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    if (_pageController!.page == null) return;
    int page = _pageController!.page!.round();
    if (curPage == page) return;
    // log('PageController#onPageChanged: from page[$curPage]');
    dispatchEvents(lifecycleEventsInactiveAndInvisible);
    curPage = page;
    // log('PageController#onPageChanged: to page[$curPage]');
    if (ModalRoute.of(context)?.isCurrent == true) {
      dispatchEvents(lifecycleEventsVisibleAndActive);
    } else {
      dispatchEvents([LifecycleEvent.visible]);
    }
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
