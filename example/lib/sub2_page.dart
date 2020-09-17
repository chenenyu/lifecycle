import 'package:flutter/material.dart';
import 'package:lifecycle/lifecycle.dart';

class Sub2Page extends StatelessWidget {
  Sub2Page({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LifecycleWrapper(
      onLifecycleEvent: (event) {
        print('Sub2Page#${event.toString()}');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Stateless Page',
          ),
        ),
        body: Center(
          child: RaisedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('pop'),
          ),
        ),
      ),
    );
  }
}
