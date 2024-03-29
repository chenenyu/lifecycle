[![Pub Version](https://img.shields.io/pub/v/lifecycle)](https://pub.dev/packages/lifecycle)
[![pub points](https://img.shields.io/pub/points/lifecycle)](https://pub.dev/packages/lifecycle)
[![likes](https://img.shields.io/pub/likes/lifecycle)](https://pub.dev/packages/lifecycle)
![PR](https://img.shields.io/badge/PRs-welcome-blue)

# lifecycle

Lifecycle support for Flutter widgets.

### Supported widgets

- [x] `StatefulWidget`.
- [x] `StatelessWidget`(include `Dialog`).
- [x] `PageView/TabBarView` and it's children.
- [x] Nested `PageView`.
- [x] `Navigator`(Navigator 2.0 pages api).
- [x] Child of `ListView/GridView/CustomScrollView`.

### Supported lifecycle event
```dart
enum LifecycleEvent {
  push,
  visible,
  active,
  inactive,
  invisible,
  pop,
}
```

## Getting Started

### Install

1. Depend on it

```yaml
dependencies:
  lifecycle: any  # replace 'any' with version number
```

2. Install it

`flutter pub get`

3. Import it

`import 'package:lifecycle/lifecycle.dart';`

### Usage

**First of all, you should register an observer in `WidgetsApp`/`MaterialApp`, and an observer can only be used by one `Navigator`, if you have your own `Navigator`, please use a new instance of LifecycleObserver.**

```dart
import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [defaultLifecycleObserver],
      ...
    );
  }
}
```

* StatefulWidget

1. Use mixin(Recommend)
```dart
import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

// mixin LifecycleAware and LifecycleMixin on State
class _State extends State<MyStatefulWidget> with LifecycleAware, LifecycleMixin {
  @override
  void onLifecycleEvent(LifecycleEvent event) {
    print(event);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}
```

2. Use  wrapper

```dart
import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

// Wrap widget with LifecycleWrapper
class _State extends State<MyStatefulWidget> {
  @override
  Widget build(BuildContext context) {
    return LifecycleWrapper(
      onLifecycleEvent: (event) {
        print(event);
      },
      child: Scaffold(),
    );
  }
}
```

* StatelessWidget/Dialog

```dart
import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

// Normal StatelessWidget
class MyStatelessWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LifecycleWrapper(
      onLifecycleEvent: (event) {
        print(event);
      },
      child: Scaffold(),
    );
  }
}

// Dialog
showDialog(
  context: context,
  routeSettings: RouteSettings(name: 'dialog'),
  builder: (context) {
    return LifecycleWrapper(
      onLifecycleEvent: (event) {
        print(event);
      },
      child: Dialog(),
    );
  },
);
```

* PageView/TabBarView

```dart
import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

class MyPageView extends StatefulWidget {
  MyPageView({Key key}) : super(key: key);

  _MyPageViewState createState() => _MyPageViewState();
}

class _MyPageViewState extends State<MyPageView> {
  PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MyPageView'),
      ),
      // Wrap PageView
      body: PageViewLifecycleWrapper(
        child: PageView(
          controller: _pageController,
          children: [
            // Wrap child of PageView
            ChildPageLifecycleWrapper(
              index: 0,
              wantKeepAlive: true,
              onLifecycleEvent: (event) {
                print('Page@0#${event.name}');
              },
              child: Container(),
            ),
            ChildPageLifecycleWrapper(
              index: 1,
              wantKeepAlive: true,
              onLifecycleEvent: (event) {
                print('Page@1#${event.name}');
              },
              child: Container(),
            ),
          ],
        ),
      ),
    );
  }
}

```

* Nested PageView

```dart
import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

class NestedPageView extends StatefulWidget {
  NestedPageView({Key key}) : super(key: key);

  _NestedPageViewState createState() => _NestedPageViewState();
}

class _NestedPageViewState extends State<NestedPageView> with SingleTickerProviderStateMixin {
  PageController _pageController;
  TabController _tabController;

  final List<Tab> myTabs = <Tab>[
    Tab(text: 'left'),
    Tab(text: 'right'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _tabController = TabController(vsync: this, length: myTabs.length);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('NestedPageView'),
        bottom: TabBar(
          controller: _tabController,
          tabs: myTabs,
        ),
      ),
      body: PageViewLifecycleWrapper( // Outer PageView
        child: TabBarView(
          controller: _tabController,
          children: <Widget>[
            ChildPageLifecycleWrapper(
              index: 0,
              wantKeepAlive: true,
              onLifecycleEvent: (event) {
                print('OuterPage@0#${event.name}');
              },
              child: Container(),
            ),
            ChildPageLifecycleWrapper(
              index: 1,
              wantKeepAlive: true,
              onLifecycleEvent: (event) {
                print('OuterPage@1#${event.name}');
              },
              child: PageViewLifecycleWrapper( // Inner PageView
                child: PageView(
                  controller: _pageController,
                  children: [
                    ChildPageLifecycleWrapper(
                      index: 0,
                      wantKeepAlive: false,
                      onLifecycleEvent: (event) {
                        log.add('InnerPage@0#${event.name}');
                      },
                      child: Container(),
                    ),
                    ChildPageLifecycleWrapper(
                      index: 1,
                      wantKeepAlive: false,
                      onLifecycleEvent: (event) {
                        log.add('InnerPage@1#${event.name}');
                      },
                      child: Container(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

```

* ListView

```dart
@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('ListPage'),
    ),
    body: ListView.builder(
      itemCount: _data.length,
      itemBuilder: (context, index) {
        return ScrollViewItemLifecycleWrapper(
          onLifecycleEvent: (LifecycleEvent event) {
            print('ListPage(item$index)#${event.name}');
          },
          wantKeepAlive: false,
          child: ListTile(
            title: Text(
              _data[index],
            ),
          ),
        );
      },
    ),
  );
}
```

### Other APIs

* Iterates routes.

```
defaultLifecycleObserver.iterateRoutes(bool Function(route) callback);
```

* Remove a route.

```
defaultLifecycleObserver.removeRoute<T>(Route route, [T? result]);
```

* Dispose a LifecycleObserver when it will never be used.

```
defaultLifecycleObserver.dispose();
```

