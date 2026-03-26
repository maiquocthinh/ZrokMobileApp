enum TaskStatus { running, stopped, error }

class TaskEntry {
  final String id;
  final String envId;
  final String command;
  TaskStatus status;
  String? shareUrl;
  final DateTime startTime;
  DateTime? endTime;
  final List<String> logs;

  TaskEntry({
    required this.id,
    required this.envId,
    required this.command,
    this.status = TaskStatus.running,
    this.shareUrl,
    DateTime? startTime,
    this.endTime,
    List<String>? logs,
  })  : startTime = startTime ?? DateTime.now(),
        logs = logs ?? [];

  Duration get uptime {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  String get uptimeFormatted {
    final d = uptime;
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    if (d.inMinutes > 0) return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
    return '${d.inSeconds}s';
  }

  bool get isRunning => status == TaskStatus.running;

  void addLog(String line) => logs.add(line);
}
