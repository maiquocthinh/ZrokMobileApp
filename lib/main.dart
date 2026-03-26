import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'managers/app_manager.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppManager(),
      child: const ZrokApp(),
    ),
  );
}

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
    final manager = context.read<AppManager>();
    await manager.init();
    if (mounted) {
      setState(() => _initialized = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Zrok Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      builder: (context, child) {
        if (!_initialized) {
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: AppTheme.teal),
                  SizedBox(height: 16),
                  Text('Loading...', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              ),
            ),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
