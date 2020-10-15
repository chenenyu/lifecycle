import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

import 'overlay_log.dart';

class Nav2Page1 extends StatefulWidget {
  final VoidCallback onShowPage2;

  Nav2Page1({Key key, this.onShowPage2}) : super(key: key);

  @override
  _Nav2Page1State createState() {
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
        title: Text('Page1'),
        leading: BackButton(
          onPressed: () {
            Navigator.of(context, rootNavigator: true).maybePop();
          },
        ),
      ),
      body: Center(
        child: TextButton(
          onPressed: widget.onShowPage2,
          child: Text('Open Page2'),
        ),
      ),
    );
  }

  @override
  void onLifecycleEvent(LifecycleEvent event) {
    log.add('Nav2Page1($hashCode)#${event.toString()}');
  }
}
