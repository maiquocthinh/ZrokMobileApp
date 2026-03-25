import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'managers/app_manager.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppManager()..init(),
      child: const ZrokApp(),
    ),
  );
}

class ZrokApp extends StatelessWidget {
  const ZrokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zrok Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
