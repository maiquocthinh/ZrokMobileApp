import '../../../core/infrastructure/storage/local_storage_data_source.dart';
import '../domain/entities/history_entry.dart';
import '../domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({required LocalStorageDataSource storage})
    : _storage = storage;

  final LocalStorageDataSource _storage;

  @override
  Future<List<HistoryEntry>> loadHistory() async {
    return _storage.loadHistory();
  }

  @override
  Future<void> saveHistory(List<HistoryEntry> history) {
    return _storage.saveHistory(history);
  }
}
