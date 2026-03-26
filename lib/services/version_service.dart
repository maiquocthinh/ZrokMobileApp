import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/zrok_version.dart';

class VersionService {
  static const _apiUrl = 'https://api.github.com/repos/openziti/zrok/releases';
  static const _versionDir = 'zrok_versions';

  /// Fetch available versions from GitHub Releases API.
  Future<List<ZrokVersion>> fetchRemoteVersions() async {
    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );
      if (response.statusCode != 200) return [];

      final releases = jsonDecode(response.body) as List;
      final versions = <ZrokVersion>[];

      for (final release in releases) {
        final tagName = (release['tag_name'] as String?)?.replaceFirst('v', '') ?? '';
        if (tagName.isEmpty) continue;

        final assets = release['assets'] as List? ?? [];
        // Look for android-arm64 binary
        String? downloadUrl;
        int size = 0;
        for (final asset in assets) {
          final name = (asset['name'] as String?) ?? '';
          if (name.contains('linux') && name.contains('arm64')) {
            downloadUrl = asset['browser_download_url'] as String?;
            size = asset['size'] as int? ?? 0;
            break;
          }
        }

        versions.add(ZrokVersion(
          version: tagName,
          downloadUrl: downloadUrl ?? '',
          sizeBytes: size,
          releaseDate: DateTime.tryParse(release['published_at'] as String? ?? ''),
        ));
      }

      return versions;
    } catch (e) {
      return [];
    }
  }

  /// Get the base directory for storing zrok binaries.
  Future<Directory> _getVersionDir() async {
    final appDir = await getApplicationSupportDirectory();
    return Directory('${appDir.path}/$_versionDir');
  }

  /// Download a specific version binary.
  /// Returns a stream of progress (0.0 to 1.0).
  Stream<double> downloadVersion(ZrokVersion version) async* {
    if (version.downloadUrl.isEmpty) return;

    final dir = await _getVersionDir();
    final versionDir = Directory('${dir.path}/v${version.version}');
    if (!await versionDir.exists()) {
      await versionDir.create(recursive: true);
    }

    final filePath = '${versionDir.path}/zrok';
    final request = http.Request('GET', Uri.parse(version.downloadUrl));
    final response = await http.Client().send(request);

    final totalBytes = response.contentLength ?? version.sizeBytes;
    var receivedBytes = 0;

    final file = File(filePath);
    final sink = file.openWrite();

    await for (final chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        yield receivedBytes / totalBytes;
      }
    }
    await sink.close();

    // Make executable on Linux/Android
    if (!Platform.isWindows) {
      await Process.run('chmod', ['+x', filePath]);
    }

    version.localPath = filePath;
    version.isDownloaded = true;
    yield 1.0;
  }

  /// Delete a downloaded version.
  Future<void> deleteVersion(ZrokVersion version) async {
    if (version.localPath != null) {
      final dir = Directory(version.localPath!).parent;
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
      version.localPath = null;
      version.isDownloaded = false;
    }
  }

  /// Check which versions are already downloaded locally.
  Future<void> syncLocalState(List<ZrokVersion> versions) async {
    final dir = await _getVersionDir();
    if (!await dir.exists()) return;

    for (final version in versions) {
      final binaryPath = '${dir.path}/v${version.version}/zrok';
      final file = File(binaryPath);
      if (await file.exists()) {
        version.localPath = binaryPath;
        version.isDownloaded = true;
      }
    }
  }

  /// Get local binary path for a version.
  Future<String?> getLocalPath(String versionTag) async {
    final dir = await _getVersionDir();
    final binaryPath = '${dir.path}/v$versionTag/zrok';
    final file = File(binaryPath);
    if (await file.exists()) return binaryPath;
    return null;
  }

  /// Get total storage used by all downloaded versions.
  Future<int> getStorageUsed() async {
    final dir = await _getVersionDir();
    if (!await dir.exists()) return 0;

    int total = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        total += await entity.length();
      }
    }
    return total;
  }
}
