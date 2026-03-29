import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../navigation/app_router.dart';
import '../state/app_controller.dart';

class ZrokApp extends StatefulWidget {
  const ZrokApp({super.key});

  @override
  State<ZrokApp> createState() => _ZrokAppState();
}

class _ZrokAppState extends State<ZrokApp> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final controller = context.read<AppController>();
    await controller.init();

    if (!mounted) return;
    setState(() => _initialized = true);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zrok Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        if (_initialized) {
          return child ?? const SizedBox.shrink();
        }

        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.teal),
                SizedBox(height: 16),
                Text(
                  'Loading...',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
