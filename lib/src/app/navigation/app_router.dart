import 'package:go_router/go_router.dart';
import '../../features/environments/presentation/screens/environments_screen.dart';
import '../../features/history/presentation/screens/history_screen.dart';
import '../../features/quick_actions/presentation/screens/quick_actions_screen.dart';
import '../../features/tasks/presentation/screens/dashboard_screen.dart';
import '../../features/tasks/presentation/screens/task_logs_screen.dart';
import '../../features/versions/presentation/screens/versions_screen.dart';
import 'shell_scaffold.dart';

final appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/history',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HistoryScreen()),
        ),
        GoRoute(
          path: '/quick-actions',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: QuickActionsScreen()),
        ),
        GoRoute(
          path: '/environments',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EnvironmentsScreen()),
        ),
        GoRoute(
          path: '/versions',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: VersionsScreen()),
        ),
      ],
    ),
    // Full-screen routes (outside shell)
    GoRoute(
      path: '/logs/:taskId',
      builder: (context, state) =>
          TaskLogsScreen(taskId: state.pathParameters['taskId']!),
    ),
  ],
);
