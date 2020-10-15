import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class Nav2Page2 extends StatefulWidget {
  final VoidCallback onHidePage1;

  Nav2Page2({Key key, this.onHidePage1}) : super(key: key);

  @override
  _Nav2Page2State createState() {
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
        title: Text('Page2'),
        // leading: BackButton(
        //   onPressed: () {
        //     Navigator.of(context, rootNavigator: true).maybePop();
        //   },
        // ),
      ),
      body: Center(
        child: TextButton(
          onPressed: widget.onHidePage1,
          child: Text('Hide Page1'),
        ),
      ),
    );
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    log.add('Nav2Page2($hashCode)#${event.toString()}');
  }
}
