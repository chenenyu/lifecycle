import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class Nav2Page2 extends StatefulWidget {
  final VoidCallback onHidePage2;

  const Nav2Page2({super.key, required this.onHidePage2});

  @override
  State createState() {
    return _Nav2Page2State();
  }
}

class _Nav2Page2State extends State<Nav2Page2>
    with LifecycleAware, LifecycleMixin {
  @override
  void initState() {
    super.initState();
    // log.add('Nav2Page2($hashCode)#initState()');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // print('Nav2Page2($hashCode)#didChangeDependencies() route(${ModalRoute.of(context).hashCode})');
  }

  @override
  void dispose() {
    // log.add('Nav2Page2($hashCode)#dispose()');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page2'),
        // leading: BackButton(
        //   onPressed: () {
        //     Navigator.of(context, rootNavigator: true).maybePop();
        //   },
        // ),
      ),
      body: Center(
        child: TextButton(
          onPressed: widget.onHidePage2,
          child: const Text('Hide Page2'),
        ),
      ),
    );
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    log.add('Nav2Page2($hashCode)#${event.name}');
  }
}
