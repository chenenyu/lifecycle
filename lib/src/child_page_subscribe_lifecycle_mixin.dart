import 'package:flutter/widgets.dart';

import 'lifecycle_aware.dart';
import 'page_view_dispatch_lifecycle_mixin.dart';

/// Subscribe lifecycle event from [PageViewDispatchLifecycleMixin].
/// This is used in child page of PageView.
mixin ChildPageSubscribeLifecycleMixin<T extends StatefulWidget>
    on State<T>, LifecycleAware {
  PageViewDispatchLifecycleMixin? _pageViewDispatchLifecycleMixin;

  @override
  void initState() {
    super.initState();
    handleLifecycleEvents([LifecycleEvent.push]);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute? route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;

    if (itemIndex == null) {
      throw FlutterError(
          'State must override getter \'itemIndex\' from LifecycleAware and return a non-null value.');
    }

    _pageViewDispatchLifecycleMixin = null;
    context.visitAncestorElements((element) {
      if (element is StatefulElement &&
          element.state is PageViewDispatchLifecycleMixin) {
        _pageViewDispatchLifecycleMixin =
            element.state as PageViewDispatchLifecycleMixin;
        return false;
      }
      return true;
    });

    _pageViewDispatchLifecycleMixin?.subscribe(itemIndex!, this);
  }

  @override
  void dispose() {
    handleLifecycleEvents([LifecycleEvent.pop]);
    _pageViewDispatchLifecycleMixin?.unsubscribe(this);
    super.dispose();
  }
}
