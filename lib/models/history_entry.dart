class HistoryEntry {
  final String id;
  final String command;
  final String envId;
  final String envName;
  final String? zrokVersion;
  final DateTime timestamp;

  HistoryEntry({
    required this.id,
    required this.command,
    required this.envId,
    required this.envName,
    this.zrokVersion,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'command': command,
        'envId': envId,
        'envName': envName,
        'zrokVersion': zrokVersion,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) => HistoryEntry(
        id: json['id'] as String,
        command: json['command'] as String,
        envId: json['envId'] as String,
        envName: json['envName'] as String,
        zrokVersion: json['zrokVersion'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
