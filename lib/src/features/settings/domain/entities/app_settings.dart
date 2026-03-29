class AppSettings {
  bool notificationsEnabled;
  bool autoReconnect;
  String? defaultZrokVersion; // null = latest installed

  AppSettings({
    this.notificationsEnabled = true,
    this.autoReconnect = true,
    this.defaultZrokVersion,
  });

  Map<String, dynamic> toJson() => {
    'notificationsEnabled': notificationsEnabled,
    'autoReconnect': autoReconnect,
    'defaultZrokVersion': defaultZrokVersion,
  };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    autoReconnect: json['autoReconnect'] as bool? ?? true,
    defaultZrokVersion: json['defaultZrokVersion'] as String?,
  );
}
