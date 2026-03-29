class EnvInfo {
  final String id;
  String name;
  String endpoint;
  bool enabled;
  String? zrokVersion; // null = use default version

  EnvInfo({
    required this.id,
    required this.name,
    required this.endpoint,
    this.enabled = false,
    this.zrokVersion,
  });

  String get maskedToken => '●●●●●●';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'endpoint': endpoint,
    'enabled': enabled,
    'zrokVersion': zrokVersion,
  };

  factory EnvInfo.fromJson(Map<String, dynamic> json) => EnvInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    endpoint: json['endpoint'] as String,
    enabled: json['enabled'] as bool? ?? false,
    zrokVersion: json['zrokVersion'] as String?,
  );
}
