
import 'package:go_router/go_router.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/history/history_screen.dart';
import '../screens/quick_actions/quick_actions_screen.dart';
import '../screens/environments/environments_screen.dart';
import '../screens/versions/versions_screen.dart';
import '../screens/logs/task_logs_screen.dart';
import 'shell_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryScreen(),
          ),
        ),
        GoRoute(
          path: '/quick-actions',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: QuickActionsScreen(),
          ),
        ),
        GoRoute(
          path: '/environments',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: EnvironmentsScreen(),
          ),
        ),
        GoRoute(
          path: '/versions',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: VersionsScreen(),
          ),
        ),
      ],
    ),
    // Full-screen routes (outside shell)
    GoRoute(
      path: '/logs/:taskId',
      builder: (context, state) => TaskLogsScreen(
        taskId: state.pathParameters['taskId']!,
      ),
    ),
  ],
);
