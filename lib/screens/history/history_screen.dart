import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../managers/app_manager.dart';
import '../../models/history_entry.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppManager>(
      builder: (context, manager, _) {
        final results = manager.searchHistory(_query);
        final grouped = _groupByDate(results);

        return RefreshIndicator(
          color: AppTheme.teal,
          onRefresh: () async {},
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: true,
                title: const Text('History'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: results.isEmpty ? null : () => _confirmClear(manager),
                  ),
                ],
              ),
              // Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, size: 20),
                      hintText: 'Search commands...',
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ),
              if (results.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(icon: Icons.history, title: 'No commands yet'),
                )
              else
                ...grouped.entries.map((group) => _buildGroup(manager, group.key, group.value)),
            ],
          ),
        );
      },
    );
  }

  Map<String, List<HistoryEntry>> _groupByDate(List<HistoryEntry> entries) {
    final groups = <String, List<HistoryEntry>>{};
    final now = DateTime.now();
    for (final entry in entries) {
      String label;
      final diff = now.difference(entry.timestamp).inDays;
      if (diff == 0) {
        label = 'Today';
      } else if (diff == 1) {
        label = 'Yesterday';
      } else {
        label = DateFormat('MMM d').format(entry.timestamp);
      }
      groups.putIfAbsent(label, () => []).add(entry);
    }
    return groups;
  }

  Widget _buildGroup(AppManager manager, String label, List<HistoryEntry> entries) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(label,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            );
          }
          final entry = entries[index - 1];
          return _buildHistoryCard(manager, entry);
        },
        childCount: entries.length + 1,
      ),
    );
  }

  Widget _buildHistoryCard(AppManager manager, HistoryEntry entry) {
    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: AppTheme.teal.withValues(alpha: 0.15),
        child: const Icon(Icons.play_arrow_rounded, color: AppTheme.teal),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppTheme.error.withValues(alpha: 0.15),
        child: const Icon(Icons.delete_outline, color: AppTheme.error),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          manager.runTask(entry.command);
          return false;
        } else {
          manager.deleteHistory(entry.id);
          return true;
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('zrok ${entry.command}', style: AppTheme.mono),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.envName}${entry.zrokVersion != null ? ' · v${entry.zrokVersion}' : ''} · ${DateFormat.Hm().format(entry.timestamp)}',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              _iconBtn(Icons.play_arrow_rounded, () => manager.runTask(entry.command)),
              _iconBtn(Icons.star_outline, () => _saveAsQuickAction(manager, entry)),
              _iconBtn(Icons.delete_outline, () => manager.deleteHistory(entry.id)),
            ],
          ),
        ),
      ),
    );
  }

  void _saveAsQuickAction(AppManager manager, HistoryEntry entry) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Save as Quick Action'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                manager.saveHistoryAsQuickAction(entry, controller.text);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmClear(AppManager manager) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Delete all history entries?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { manager.clearHistory(); Navigator.pop(ctx); },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 32, height: 32,
      child: IconButton(icon: Icon(icon, size: 16), padding: EdgeInsets.zero, onPressed: onTap),
    );
  }
}
