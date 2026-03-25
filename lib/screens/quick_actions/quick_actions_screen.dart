import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../managers/app_manager.dart';
import '../../models/quick_action.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

class QuickActionsScreen extends StatelessWidget {
  const QuickActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppManager>(
      builder: (context, manager, _) {
        final actions = manager.quickActions;

        return CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: const Text('Quick Actions'),
              actions: [
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                  onPressed: () => _showAddEditDialog(context, manager),
                ),
              ],
            ),
            if (actions.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.bolt,
                  title: 'No quick actions',
                  subtitle: 'Save commands from History or tap Add',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, index) => _buildCard(context, manager, actions[index]),
                  childCount: actions.length,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCard(BuildContext context, AppManager manager, QuickAction action) {
    final env = manager.getEnv(action.envId);
    final envName = env?.name ?? 'Unknown';
    final version = env?.zrokVersion ?? manager.settings.defaultZrokVersion;

    return Dismissible(
      key: Key(action.id),
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
          manager.selectEnv(action.envId);
          manager.runTask(action.command);
          return false;
        } else {
          manager.deleteQuickAction(action.id);
          return true;
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded, size: 16, color: AppTheme.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(action.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('zrok ${action.command}', style: AppTheme.mono),
              const SizedBox(height: 4),
              Text('$envName${version != null ? ' (v$version)' : ''}',
                  style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 10),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: const Text('Run'),
                    onPressed: () {
                      manager.selectEnv(action.envId);
                      manager.runTask(action.command);
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _showAddEditDialog(context, manager, action: action),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () => manager.deleteQuickAction(action.id),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, AppManager manager, {QuickAction? action}) {
    final nameCtrl = TextEditingController(text: action?.name ?? '');
    final cmdCtrl = TextEditingController(text: action?.command ?? '');
    String selectedEnvId = action?.envId ?? (manager.enabledEnvs.isNotEmpty ? manager.enabledEnvs.first.id : '');
    final isEdit = action != null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isEdit ? 'Edit Quick Action' : 'New Quick Action'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Name')),
              const SizedBox(height: 12),
              TextField(controller: cmdCtrl, decoration: const InputDecoration(hintText: 'Command (e.g. share public)')),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedEnvId.isEmpty ? null : selectedEnvId,
                decoration: const InputDecoration(hintText: 'Environment'),
                dropdownColor: AppTheme.surfaceContainerHighest,
                items: manager.enabledEnvs.map((e) => DropdownMenuItem(value: e.id, child: Text(e.name))).toList(),
                onChanged: (v) => setDialogState(() => selectedEnvId = v ?? ''),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty || cmdCtrl.text.isEmpty || selectedEnvId.isEmpty) return;
                if (isEdit) {
                  manager.updateQuickAction(action.id, nameCtrl.text, cmdCtrl.text, selectedEnvId);
                } else {
                  manager.addQuickAction(nameCtrl.text, cmdCtrl.text, selectedEnvId);
                }
                Navigator.pop(ctx);
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
