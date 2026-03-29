import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  static const _tabs = [
    _Tab('/dashboard', Icons.home_rounded, Icons.home_outlined, 'Home'),
    _Tab('/history', Icons.history_rounded, Icons.history_outlined, 'History'),
    _Tab('/quick-actions', Icons.bolt_rounded, Icons.bolt_outlined, 'Quick'),
    _Tab(
      '/environments',
      Icons.language_rounded,
      Icons.language_outlined,
      'Envs',
    ),
    _Tab(
      '/versions',
      Icons.inventory_2_rounded,
      Icons.inventory_2_outlined,
      'Versions',
    ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.iconOutlined),
                selectedIcon: Icon(tab.iconFilled),
                label: tab.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Tab {
  final String path;
  final IconData iconFilled;
  final IconData iconOutlined;
  final String label;
  const _Tab(this.path, this.iconFilled, this.iconOutlined, this.label);
}
