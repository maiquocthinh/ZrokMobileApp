import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart' show Share;
import '../../managers/app_manager.dart';
import '../../models/task_entry.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _commandController = TextEditingController();

  @override
  void dispose() {
    _commandController.dispose();
    super.dispose();
  }

  void _runCommand(AppManager manager) {
    final text = _commandController.text.trim();
    if (text.isEmpty) return;
    manager.runTask(text);
    _commandController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppManager>(
      builder: (context, manager, _) {
        return RefreshIndicator(
          color: AppTheme.teal,
          onRefresh: () async { /* force rebuild */ },
          child: CustomScrollView(
            slivers: [
              // -- AppBar --
              SliverAppBar(
                floating: true,
                title: const Text('Zrok Mobile'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => context.go('/environments'),
                  ),
                ],
              ),

              // -- Env Selector --
              SliverToBoxAdapter(child: _buildEnvSelector(manager)),

              // -- Command Input --
              SliverToBoxAdapter(child: _buildCommandInput(manager)),

              // -- Running Tasks Header --
              SliverToBoxAdapter(child: _buildTasksHeader(manager)),

              // -- Task List --
              if (manager.runningTasks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.play_arrow_rounded,
                    title: 'No tasks running',
                    subtitle: 'Enter a command above to start a tunnel',
                  ),
                )
              else
                _buildTaskList(manager),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnvSelector(AppManager manager) {
    final envs = manager.enabledEnvs;
    final selected = manager.selectedEnv;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          if (envs.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: manager.selectedEnvId,
                  isDense: true,
                  dropdownColor: AppTheme.surfaceContainerHighest,
                  style: Theme.of(context).textTheme.titleSmall,
                  items: envs.map((env) => DropdownMenuItem(
                    value: env.id,
                    child: Text(env.name),
                  )).toList(),
                  onChanged: (id) => id != null ? manager.selectEnv(id) : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.circle, size: 8, color: selected?.enabled == true ? AppTheme.teal : AppTheme.outline),
            const SizedBox(width: 6),
            Text(
              selected?.enabled == true ? 'Enabled' : 'Disabled',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: selected?.enabled == true ? AppTheme.teal : AppTheme.outline),
            ),
          ] else
            Text('No environments', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildCommandInput(AppManager manager) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('\$ zrok ', style: AppTheme.mono.copyWith(color: AppTheme.teal)),
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    style: AppTheme.mono,
                    decoration: InputDecoration(
                      hintText: 'share public localhost:8080',
                      hintStyle: AppTheme.monoSmall,
                      filled: false,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _runCommand(manager),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                    onPressed: () => _runCommand(manager),
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ['share', 'access', 'reserve', 'status', 'overview'].map((cmd) =>
                ActionChip(
                  label: Text(cmd),
                  onPressed: () => _commandController.text = '$cmd ',
                ),
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksHeader(AppManager manager) {
    final count = manager.runningTaskCount;
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('Running Tasks ($count)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.stop_rounded, size: 16),
            label: const Text('Stop All'),
            onPressed: () => manager.stopAllTasks(),
          ),
        ],
      ),
    );
  }

  SliverList _buildTaskList(AppManager manager) {
    // Group tasks by env
    final grouped = <String, List<TaskEntry>>{};
    for (final task in manager.tasks.where((t) => t.isRunning)) {
      grouped.putIfAbsent(task.envId, () => []).add(task);
    }

    final widgets = <Widget>[];
    for (final entry in grouped.entries) {
      final env = manager.getEnv(entry.key);
      final envName = env?.name ?? 'Unknown';
      final version = env?.zrokVersion ?? manager.settings.defaultZrokVersion ?? 'latest';

      widgets.add(Padding(
        padding: const EdgeInsets.only(left: 16, top: 12, bottom: 4),
        child: Row(
          children: [
            Icon(Icons.label_outline, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text('$envName (v$version)',
                style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
      ));

      for (final task in entry.value) {
        widgets.add(_buildTaskCard(manager, task));
      }
    }

    return SliverList(delegate: SliverChildListDelegate(widgets));
  }

  Widget _buildTaskCard(AppManager manager, TaskEntry task) {
    return Dismissible(
      key: Key(task.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 24),
        color: AppTheme.teal.withValues(alpha: 0.15),
        child: const Icon(Icons.article_outlined, color: AppTheme.teal),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppTheme.error.withValues(alpha: 0.15),
        child: const Icon(Icons.stop_rounded, color: AppTheme.error),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          context.push('/logs/${task.id}');
          return false;
        } else {
          manager.stopTask(task.id);
          return false;
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
                  Icon(Icons.circle, size: 8,
                      color: task.isRunning ? AppTheme.teal : AppTheme.outline),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('zrok ${task.command}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              if (task.shareUrl != null) ...[
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: task.shareUrl!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copied')),
                    );
                  },
                  child: Text('→ ${task.shareUrl}', style: AppTheme.monoTeal),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(task.uptimeFormatted, style: Theme.of(context).textTheme.labelSmall),
                  const Spacer(),
                  _iconBtn(Icons.stop_rounded, () => manager.stopTask(task.id)),
                  _iconBtn(Icons.article_outlined, () => context.push('/logs/${task.id}')),
                  if (task.shareUrl != null) ...[
                    _iconBtn(Icons.copy_rounded, () {
                      Clipboard.setData(ClipboardData(text: task.shareUrl!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('URL copied')),
                      );
                    }),
                    _iconBtn(Icons.share_rounded, () {
                      Share.share(task.shareUrl!);
                    }),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: 32, height: 32,
      child: IconButton(
        icon: Icon(icon, size: 16),
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }
}
