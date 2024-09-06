import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class Nav2Page1 extends StatefulWidget {
  final VoidCallback onShowPage2;

  const Nav2Page1({super.key, required this.onShowPage2});

  @override
  State createState() {
    return _Nav2Page1State();
  }
}

class _Nav2Page1State extends State<Nav2Page1>
    with LifecycleAware, LifecycleMixin {
  @override
  void initState() {
    super.initState();
    // log.add('Nav2Page1($hashCode)#initState()');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // print('Nav2Page1($hashCode)#didChangeDependencies() route(${ModalRoute.of(context).hashCode})');
  }

  @override
  void dispose() {
    // log.add('Nav2Page1($hashCode)#dispose()');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page1'),
        leading: BackButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).maybePop();
          },
        ),
      ),
      body: Center(
        child: TextButton(
          onPressed: widget.onShowPage2,
          child: const Text('Open Page2'),
        ),
      ),
    );
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    log.add('Nav2Page1($hashCode)#${event.name}');
  }
}
