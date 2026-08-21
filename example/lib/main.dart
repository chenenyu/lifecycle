/*
 * example 应用的进程入口。
 *
 * 这里只负责启动根 Widget，所有生命周期装配放在 app.dart，保持启动代码无状态，便于
 * Widget test 和 integration_test 直接复用同一个 LifecycleExampleApp。
 */
import 'package:flutter/widgets.dart';

import 'app.dart';

export 'app.dart' show LifecycleExampleApp;

void main() => runApp(const LifecycleExampleApp());
