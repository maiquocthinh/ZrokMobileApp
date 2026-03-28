import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../managers/app_manager.dart';
import '../../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class TaskLogsScreen extends StatefulWidget {
  final String taskId;
  const TaskLogsScreen({super.key, required this.taskId});
  @override
  State<TaskLogsScreen> createState() => _TaskLogsScreenState();
}

class _TaskLogsScreenState extends State<TaskLogsScreen> {
  final _scrollController = ScrollController();
  bool _autoScroll = true;
  String _filter = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
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

  // Parse log level prefix
  _LogLevel _parseLevel(String line) {
    if (line.startsWith('[err]') || line.startsWith('[error]')) return _LogLevel.error;
    if (line.startsWith('[warn]') || line.startsWith('[WARNING]')) return _LogLevel.warning;
    if (line.startsWith('[url]')) return _LogLevel.url;
    if (line.startsWith('[info]')) return _LogLevel.info;
    if (line.startsWith('[req]')) return _LogLevel.request;
    return _LogLevel.plain;
  }

  Color _levelColor(_LogLevel level) {
    switch (level) {
      case _LogLevel.error:
        return const Color(0xFFFF6B6B);
      case _LogLevel.warning:
        return AppTheme.amber;
      case _LogLevel.url:
        return AppTheme.teal;
      case _LogLevel.info:
        return const Color(0xFF8B8AFF);
      case _LogLevel.request:
        return const Color(0xFF9CA3AF);
      case _LogLevel.plain:
        return const Color(0xFFD1D5DB);
    }
  }

  Color _levelBadgeColor(_LogLevel level) {
    switch (level) {
      case _LogLevel.error:
        return const Color(0xFFFF6B6B).withValues(alpha: 0.15);
      case _LogLevel.warning:
        return AppTheme.amber.withValues(alpha: 0.15);
      case _LogLevel.url:
        return AppTheme.teal.withValues(alpha: 0.15);
      case _LogLevel.info:
        return const Color(0xFF8B8AFF).withValues(alpha: 0.10);
      case _LogLevel.request:
        return const Color(0xFF9CA3AF).withValues(alpha: 0.08);
      case _LogLevel.plain:
        return Colors.transparent;
    }
  }

  String _levelLabel(_LogLevel level) {
    switch (level) {
      case _LogLevel.error:
        return 'ERR';
      case _LogLevel.warning:
        return 'WRN';
      case _LogLevel.url:
        return 'URL';
      case _LogLevel.info:
        return 'INF';
      case _LogLevel.request:
        return 'REQ';
      case _LogLevel.plain:
        return '   ';
    }
  }

  IconData _levelIcon(_LogLevel level) {
    switch (level) {
      case _LogLevel.error:
        return Icons.error_outline_rounded;
      case _LogLevel.warning:
        return Icons.warning_amber_rounded;
      case _LogLevel.url:
        return Icons.link_rounded;
      case _LogLevel.info:
        return Icons.info_outline_rounded;
      case _LogLevel.request:
        return Icons.arrow_forward_rounded;
      case _LogLevel.plain:
        return Icons.chevron_right_rounded;
    }
  }

  // Strip the log prefix like [info], [err], etc
  String _stripPrefix(String line) {
    final prefixes = ['[error]', '[err]', '[warn]', '[WARNING]', '[url]', '[info]', '[req]'];
    for (final p in prefixes) {
      if (line.startsWith(p)) {
        return line.substring(p.length).trimLeft();
      }
    }
    return line;
  }

  void _copyAllLogs(List<String> logs) {
    final text = logs.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${logs.length} lines to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
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

        // Filter logs
        final allLogs = task.logs;
        final filteredLogs = _filter.isEmpty
            ? allLogs
            : allLogs.where((l) => l.toLowerCase().contains(_filter.toLowerCase())).toList();

        _scrollToBottom();

        // Count log levels
        int errorCount = 0, warnCount = 0, infoCount = 0;
        for (final log in allLogs) {
          final level = _parseLevel(log);
          if (level == _LogLevel.error) errorCount++;
          else if (level == _LogLevel.warning) warnCount++;
          else if (level == _LogLevel.info) infoCount++;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'zrok ${task.command}',
              style: GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              // Search toggle
              IconButton(
                icon: Icon(
                  _showSearch ? Icons.search_off_rounded : Icons.search_rounded,
                  size: 20,
                ),
                tooltip: 'Search Logs',
                onPressed: () {
                  setState(() {
                    _showSearch = !_showSearch;
                    if (_showSearch) {
                      _searchFocusNode.requestFocus();
                    } else {
                      _filter = '';
                      _searchController.clear();
                    }
                  });
                },
              ),
              if (task.isRunning)
                IconButton(
                  icon: const Icon(Icons.stop_circle_rounded, color: Color(0xFFFF6B6B), size: 22),
                  tooltip: 'Stop Task',
                  onPressed: () => manager.stopTask(task.id),
                ),
            ],
          ),
          body: Column(
            children: [
              // Status header card
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: task.isRunning
                        ? AppTheme.teal.withValues(alpha: 0.3)
                        : AppTheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    // Status indicator
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: task.isRunning ? AppTheme.teal : AppTheme.outline,
                        boxShadow: task.isRunning
                            ? [BoxShadow(color: AppTheme.teal.withValues(alpha: 0.5), blurRadius: 6)]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      task.isRunning ? 'RUNNING' : (task.status.name == 'error' ? 'ERROR' : 'STOPPED'),
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: task.isRunning ? AppTheme.teal : AppTheme.outline,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.timer_outlined, size: 13, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      task.uptimeFormatted,
                      style: GoogleFonts.jetBrainsMono(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                    const Spacer(),
                    // Log level counts
                    if (errorCount > 0) _buildCountBadge(errorCount, const Color(0xFFFF6B6B), 'E'),
                    if (warnCount > 0) ...[const SizedBox(width: 6), _buildCountBadge(warnCount, AppTheme.amber, 'W')],
                    const SizedBox(width: 6),
                    _buildCountBadge(allLogs.length, AppTheme.textSecondary, ''),
                  ],
                ),
              ),

              // Search bar
              if (_showSearch)
                Container(
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (v) => setState(() => _filter = v),
                    style: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppTheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Filter logs...',
                      hintStyle: GoogleFonts.jetBrainsMono(fontSize: 13, color: AppTheme.textSecondary),
                      prefixIcon: const Icon(Icons.filter_list_rounded, size: 18),
                      suffixIcon: _filter.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _filter = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppTheme.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

              // Log area — SelectionArea wraps entire list for multi-line selection
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF080818),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.outlineVariant.withValues(alpha: 0.15)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: SelectionArea(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredLogs.length,
                      itemBuilder: (ctx, index) {
                        final line = filteredLogs[index];
                        final level = _parseLevel(line);
                        final content = _stripPrefix(line);
                        // Original line number in unfiltered list
                        final lineNum = _filter.isEmpty
                            ? index + 1
                            : allLogs.indexOf(line) + 1;

                        return _buildLogLine(
                          lineNum: lineNum,
                          level: level,
                          content: content,
                          rawLine: line,
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Bottom toolbar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Auto-scroll toggle
                    GestureDetector(
                      onTap: () => setState(() => _autoScroll = !_autoScroll),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _autoScroll ? Icons.vertical_align_bottom_rounded : Icons.pause_rounded,
                            size: 16,
                            color: _autoScroll ? AppTheme.teal : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Auto-scroll',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _autoScroll ? AppTheme.teal : AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Copy all
                    _buildToolbarButton(
                      icon: Icons.copy_all_rounded,
                      label: 'Copy',
                      onTap: () => _copyAllLogs(filteredLogs),
                    ),
                    const SizedBox(width: 8),
                    // Clear logs
                    _buildToolbarButton(
                      icon: Icons.delete_sweep_rounded,
                      label: 'Clear',
                      onTap: () {
                        task.logs.clear();
                        setState(() {});
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

  Widget _buildLogLine({
    required int lineNum,
    required _LogLevel level,
    required String content,
    required String rawLine,
  }) {
    final color = _levelColor(level);
    final bgColor = _levelBadgeColor(level);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          left: BorderSide(
            color: level == _LogLevel.error
                ? const Color(0xFFFF6B6B).withValues(alpha: 0.6)
                : level == _LogLevel.warning
                    ? AppTheme.amber.withValues(alpha: 0.6)
                    : Colors.transparent,
            width: 3,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Line number
          SizedBox(
            width: 32,
            child: Text(
              '$lineNum',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                height: 1.5,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 6),

          // Level badge icon
          if (level != _LogLevel.plain) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(_levelIcon(level), size: 12, color: color.withValues(alpha: 0.7)),
            ),
            const SizedBox(width: 4),
          ],

          // Log content
          Expanded(
            child: Text(
              content,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 12,
                color: color,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(int count, Color color, String prefix) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        prefix.isEmpty ? '$count' : '$prefix:$count',
        style: GoogleFonts.jetBrainsMono(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerHigh.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

enum _LogLevel { error, warning, url, info, request, plain }
