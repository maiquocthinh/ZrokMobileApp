import '../../../core/infrastructure/storage/local_storage_data_source.dart';
import '../domain/entities/quick_action.dart';
import '../domain/repositories/quick_action_repository.dart';

class QuickActionRepositoryImpl implements QuickActionRepository {
  QuickActionRepositoryImpl({required LocalStorageDataSource storage})
    : _storage = storage;

  final LocalStorageDataSource _storage;

  @override
  Future<List<QuickAction>> loadQuickActions() async {
    return _storage.loadQuickActions();
  }

  @override
  Future<void> saveQuickActions(List<QuickAction> actions) {
    return _storage.saveQuickActions(actions);
  }
}
