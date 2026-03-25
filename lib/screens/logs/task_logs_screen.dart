import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../managers/app_manager.dart';

import '../../theme/app_theme.dart';

class TaskLogsScreen extends StatefulWidget {
  final String taskId;
  const TaskLogsScreen({super.key, required this.taskId});
  @override
  State<TaskLogsScreen> createState() => _TaskLogsScreenState();
}

class _TaskLogsScreenState extends State<TaskLogsScreen> {
  final _scrollController = ScrollController();
  bool _autoScroll = true;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_autoScroll && _scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Color _logColor(String line) {
    if (line.startsWith('[err]') || line.startsWith('[error]')) return AppTheme.errorLight;
    if (line.startsWith('[url]')) return AppTheme.teal;
    if (line.startsWith('[info]')) return const Color(0xFFC4C0FF);
    if (line.startsWith('[req]')) {
      if (line.contains('4') || line.contains('5')) return AppTheme.amber;
      return AppTheme.textSecondary;
    }
    return AppTheme.onSurfaceVariant;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppManager>(
      builder: (context, manager, _) {
        final task = manager.getTask(widget.taskId);
        if (task == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Task Not Found')),
            body: const Center(child: Text('This task no longer exists.')),
          );
        }

        _scrollToBottom();

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('zrok ${task.command}', style: const TextStyle(fontSize: 16)),
              ],
            ),
            actions: [
              if (task.isRunning)
                IconButton(
                  icon: const Icon(Icons.stop_rounded),
                  onPressed: () => manager.stopTask(task.id),
                ),
            ],
          ),
          body: Column(
            children: [
              // Status bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.surfaceContainerLow,
                child: Row(
                  children: [
                    Icon(Icons.circle, size: 8,
                        color: task.isRunning ? AppTheme.teal : AppTheme.outline),
                    const SizedBox(width: 8),
                    Text(
                      task.isRunning ? 'Running' : 'Stopped',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: task.isRunning ? AppTheme.teal : AppTheme.outline),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.timer_outlined, size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(task.uptimeFormatted, style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),

              // Log area
              Expanded(
                child: Container(
                  color: AppTheme.surfaceContainerLowest,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: task.logs.length,
                    itemBuilder: (ctx, index) {
                      final line = task.logs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: SelectableText(
                          line,
                          style: AppTheme.monoSmall.copyWith(color: _logColor(line)),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Bottom toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: AppTheme.surfaceContainerLow,
                child: Row(
                  children: [
                    const Text('Auto-scroll', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 8),
                    Switch(
                      value: _autoScroll,
                      onChanged: (v) => setState(() => _autoScroll = v),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      tooltip: 'Copy All',
                      onPressed: () {
                        // Copy all logs to clipboard
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, size: 18),
                      tooltip: 'Share Logs',
                      onPressed: () {
                        // Share logs
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
