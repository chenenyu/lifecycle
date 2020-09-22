



# lifecycle

Lifecycle support for Flutter widgets.

### Supported widgets

- [x] `StatefulWidget`.
- [x] `StatelessWidget`(include `Dialog`).
- [x] `PageView` and it's children.
- [x] `TabBarView` and it's children.

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
  lifecycle: ^0.0.1
```

2. Install it

`flutter pub get`

3. Import it

`import 'package:lifecycle/lifecycle.dart';`

### Usage

First of all, you should register a observer in `WidgetsApp`/`MaterialApp`:  
```dart
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
      child: AlertDialog(),
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
        controller: _pageController,
        onLifecycleEvent: (event) { // optional.
          print('MyPageView#${event.toString()}');
        },
        child: PageView(
          controller: _pageController,
          children: [
            // Wrap child of PageView
            PageLifecycleWrapper(
              index: 0,
              wantKeepAlive: true,
              onLifecycleEvent: (event) {
                print('Page@0#${event.toString()}');
              },
              child: Container(),
            ),
            PageLifecycleWrapper(
              index: 1,
              wantKeepAlive: true,
              onLifecycleEvent: (event) {
                print('Page@1#${event.toString()}');
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
