import '../../../core/infrastructure/storage/local_storage_data_source.dart';
import '../domain/entities/app_settings.dart';
import '../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl({required LocalStorageDataSource storage})
    : _storage = storage;

  final LocalStorageDataSource _storage;

  @override
  Future<AppSettings> loadSettings() async {
    return _storage.loadSettings();
  }

  @override
  Future<void> saveSettings(AppSettings settings) {
    return _storage.saveSettings(settings);
  }
}
