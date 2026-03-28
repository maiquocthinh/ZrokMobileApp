class ZrokVersion {
  final String version;
  final String downloadUrl;
  final String assetName;
  String? localPath;
  bool isDownloaded;
  int sizeBytes;
  DateTime? releaseDate;

  ZrokVersion({
    required this.version,
    required this.downloadUrl,
    this.assetName = 'libzrok.so',
    this.localPath,
    this.isDownloaded = false,
    this.sizeBytes = 0,
    this.releaseDate,
  });

  String get displayVersion => 'v$version';

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'downloadUrl': downloadUrl,
        'assetName': assetName,
        'localPath': localPath,
        'isDownloaded': isDownloaded,
        'sizeBytes': sizeBytes,
        'releaseDate': releaseDate?.toIso8601String(),
      };

  factory ZrokVersion.fromJson(Map<String, dynamic> json) => ZrokVersion(
        version: json['version'] as String,
        downloadUrl: json['downloadUrl'] as String,
        assetName: json['assetName'] as String? ?? 'libzrok.so',
        localPath: json['localPath'] as String?,
        isDownloaded: json['isDownloaded'] as bool? ?? false,
        sizeBytes: json['sizeBytes'] as int? ?? 0,
        releaseDate: json['releaseDate'] != null
            ? DateTime.parse(json['releaseDate'] as String)
            : null,
      );
}
