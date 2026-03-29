import 'package:flutter/widgets.dart';

import 'src/app/di/app_scope.dart';
import 'src/app/view/zrok_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AppScope(child: ZrokApp()));
}
