class QuickAction {
  final String id;
  String name;
  String command;
  String envId;

  QuickAction({
    required this.id,
    required this.name,
    required this.command,
    required this.envId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'command': command,
    'envId': envId,
  };

  factory QuickAction.fromJson(Map<String, dynamic> json) => QuickAction(
    id: json['id'] as String,
    name: json['name'] as String,
    command: json['command'] as String,
    envId: json['envId'] as String,
  );
}
