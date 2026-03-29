import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../core/infrastructure/platform/command_executor.dart';
import '../../core/infrastructure/platform/connectivity_service.dart';
import '../../core/infrastructure/platform/foreground_service.dart';
import '../../core/infrastructure/platform/notification_service.dart';
import '../../core/infrastructure/platform/version_service.dart';
import '../../core/infrastructure/storage/local_storage_data_source.dart';
import '../../core/infrastructure/storage/secure_token_store.dart';
import '../../features/environments/data/environment_repository_impl.dart';
import '../../features/history/data/history_repository_impl.dart';
import '../../features/quick_actions/data/quick_action_repository_impl.dart';
import '../../features/settings/data/settings_repository_impl.dart';
import '../../features/versions/data/version_repository_impl.dart';
import '../state/app_controller.dart';

class AppScope extends StatelessWidget {
  const AppScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppController>(
      create: (_) {
        final storage = LocalStorageDataSource();
        final secureTokenStore = SecureTokenStore();
        final versionPlatformService = VersionPlatformService();

        return AppController(
          environmentRepository: EnvironmentRepositoryImpl(
            storage: storage,
            secureTokenStore: secureTokenStore,
          ),
          historyRepository: HistoryRepositoryImpl(storage: storage),
          quickActionRepository: QuickActionRepositoryImpl(storage: storage),
          settingsRepository: SettingsRepositoryImpl(storage: storage),
          versionRepository: VersionRepositoryImpl(
            storage: storage,
            versionService: versionPlatformService,
          ),
          connectivity: ConnectivityService(),
          notifications: NotificationService(),
          foreground: ForegroundService(),
          executor: CommandExecutor(),
        );
      },
      child: child,
    );
  }
}
