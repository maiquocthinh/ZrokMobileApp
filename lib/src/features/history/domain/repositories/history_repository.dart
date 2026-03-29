import '../entities/history_entry.dart';

abstract class HistoryRepository {
  Future<List<HistoryEntry>> loadHistory();
  Future<void> saveHistory(List<HistoryEntry> history);
}
