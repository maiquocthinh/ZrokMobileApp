import '../entities/quick_action.dart';

abstract class QuickActionRepository {
  Future<List<QuickAction>> loadQuickActions();
  Future<void> saveQuickActions(List<QuickAction> actions);
}
