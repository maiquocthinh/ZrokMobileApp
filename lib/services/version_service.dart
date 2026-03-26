import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/zrok_version.dart';

class VersionService {
  static const _apiUrl = 'https://api.github.com/repos/openziti/zrok/releases';
  static const _versionDir = 'zrok_versions';
  static const _channel = MethodChannel('com.zrokapp.mobile/exec');

  /// The binary name inside the tarball.
  /// zrok v2.0.0+ renamed the binary from 'zrok' to 'zrok2'.
  static const _binaryNames = ['zrok2', 'zrok'];

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
        // Look for linux-arm64 tarball (works on Android since Go is static-linked)
        String? downloadUrl;
        int size = 0;
        for (final asset in assets) {
          final name = (asset['name'] as String?) ?? '';
          if (name.contains('linux') && name.contains('arm64') && name.endsWith('.tar.gz')) {
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

  /// Get the executable bin directory (inside app's files dir).
  Future<String> _getExecBinDir() async {
    try {
      final filesDir = await _channel.invokeMethod<String>('getFilesDir');
      if (filesDir != null) {
        final binDir = Directory('$filesDir/bin');
        if (!await binDir.exists()) {
          await binDir.create(recursive: true);
        }
        return binDir.path;
      }
    } catch (_) {}
    // Fallback to app support dir
    final dir = await _getVersionDir();
    return dir.path;
  }

  /// Download and extract zrok binary from .tar.gz release.
  /// After extraction, copies binary to executable directory.
  /// Returns a stream of progress (0.0 to 1.0).
  Stream<double> downloadVersion(ZrokVersion version) async* {
    if (version.downloadUrl.isEmpty) return;

    final dir = await _getVersionDir();
    final versionDir = Directory('${dir.path}/v${version.version}');
    if (!await versionDir.exists()) {
      await versionDir.create(recursive: true);
    }

    // Step 1: Download the .tar.gz archive
    final archivePath = '${versionDir.path}/zrok.tar.gz';
    final request = http.Request('GET', Uri.parse(version.downloadUrl));
    final response = await http.Client().send(request);

    final totalBytes = response.contentLength ?? version.sizeBytes;
    var receivedBytes = 0;

    final archiveFile = File(archivePath);
    final sink = archiveFile.openWrite();

    await for (final chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        yield (receivedBytes / totalBytes) * 0.8; // 80% for download
      }
    }
    await sink.close();
    yield 0.85;

    // Step 2: Extract the binary from tar.gz
    try {
      // Try tar command first
      final tarResult = await Process.run(
        'tar', ['xzf', archivePath, '-C', versionDir.path],
      );
      if (tarResult.exitCode != 0) {
        // Fallback: manual extraction
        await _manualExtract(archivePath, versionDir.path);
      }
    } catch (e) {
      // Manual extraction as fallback
      await _manualExtract(archivePath, versionDir.path);
    }

    // Clean up archive
    try { await archiveFile.delete(); } catch (_) {}
    yield 0.90;

    // Step 3: Find the extracted binary
    String? extractedPath;
    for (final name in _binaryNames) {
      final candidate = File('${versionDir.path}/$name');
      if (await candidate.exists()) {
        extractedPath = candidate.path;
        break;
      }
    }

    // Search recursively if not found at top level
    if (extractedPath == null) {
      await for (final entity in versionDir.list(recursive: true)) {
        if (entity is File) {
          final basename = entity.path.split('/').last.split('\\').last;
          if (_binaryNames.contains(basename)) {
            extractedPath = entity.path;
            break;
          }
        }
      }
    }
    yield 0.95;

    if (extractedPath == null) {
      yield 1.0;
      return;
    }

    // Step 4: Copy binary to executable directory with proper permissions
    try {
      final result = await _channel.invokeMethod<String>('copyToExecutableDir', {
        'srcPath': extractedPath,
        'destName': 'zrok_v${version.version}',
      });
      if (result != null) {
        version.localPath = result;
        version.isDownloaded = true;
        yield 1.0;
        return;
      }
    } catch (_) {}

    // Fallback: try to make executable in place
    try {
      await _channel.invokeMethod('makeExecutable', {'path': extractedPath});
    } catch (_) {
      // Last resort: use chmod command
      try {
        await Process.run('chmod', ['755', extractedPath]);
      } catch (_) {}
    }

    version.localPath = extractedPath;
    version.isDownloaded = true;
    yield 1.0;
  }

  /// Manual tar.gz extraction fallback using dart:io
  Future<void> _manualExtract(String archivePath, String destDir) async {
    final bytes = await File(archivePath).readAsBytes();
    final decompressed = gzip.decode(bytes);

    // Parse tar format (simplified — handles regular files)
    var offset = 0;
    while (offset < decompressed.length) {
      if (offset + 512 > decompressed.length) break;
      final header = decompressed.sublist(offset, offset + 512);

      // Check for end-of-archive
      if (header.every((b) => b == 0)) break;

      // Extract filename (bytes 0-99)
      final nameBytes = header.sublist(0, 100);
      final nameEnd = nameBytes.indexOf(0);
      final name = utf8.decode(nameBytes.sublist(0, nameEnd > 0 ? nameEnd : 100)).trim();

      // Extract file size (bytes 124-135, octal)
      final sizeStr = utf8.decode(header.sublist(124, 136)).trim().replaceAll('\x00', '');
      final fileSize = sizeStr.isNotEmpty ? int.tryParse(sizeStr, radix: 8) ?? 0 : 0;

      // File type (byte 156): '0' or '\0' = regular file
      final typeFlag = header[156];

      offset += 512;

      if ((typeFlag == 48 || typeFlag == 0) && name.isNotEmpty && fileSize > 0) {
        final fileData = decompressed.sublist(offset, offset + fileSize);
        final outPath = '$destDir/${name.split('/').last}';
        await File(outPath).writeAsBytes(fileData);
      }

      offset += ((fileSize + 511) ~/ 512) * 512;
    }
  }

  /// Delete a downloaded version.
  Future<void> deleteVersion(ZrokVersion version) async {
    // Delete from version dir
    if (version.localPath != null) {
      try {
        final file = File(version.localPath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}

      // Also try deleting the version subdirectory
      final dir = await _getVersionDir();
      final versionDir = Directory('${dir.path}/v${version.version}');
      try {
        if (await versionDir.exists()) await versionDir.delete(recursive: true);
      } catch (_) {}

      version.localPath = null;
      version.isDownloaded = false;
    }
  }

  /// Check which versions are already downloaded locally.
  Future<void> syncLocalState(List<ZrokVersion> versions) async {
    final dir = await _getVersionDir();
    String? execBinDir;
    try {
      execBinDir = await _getExecBinDir();
    } catch (_) {}

    for (final version in versions) {
      // Check executable bin dir first (preferred location)
      if (execBinDir != null) {
        final execPath = '$execBinDir/zrok_v${version.version}';
        if (await File(execPath).exists()) {
          version.localPath = execPath;
          version.isDownloaded = true;
          continue;
        }
      }

      // Check version dir
      if (await dir.exists()) {
        for (final name in _binaryNames) {
          final binaryPath = '${dir.path}/v${version.version}/$name';
          if (await File(binaryPath).exists()) {
            version.localPath = binaryPath;
            version.isDownloaded = true;
            break;
          }
        }
      }
    }
  }

  /// Get local binary path for a version.
  Future<String?> getLocalPath(String versionTag) async {
    // Check executable bin dir first
    try {
      final execBinDir = await _getExecBinDir();
      final execPath = '$execBinDir/zrok_v$versionTag';
      if (await File(execPath).exists()) return execPath;
    } catch (_) {}

    // Check version dir
    final dir = await _getVersionDir();
    for (final name in _binaryNames) {
      final binaryPath = '${dir.path}/v$versionTag/$name';
      if (await File(binaryPath).exists()) return binaryPath;
    }
    return null;
  }

  /// Get total storage used by all downloaded versions.
  Future<int> getStorageUsed() async {
    int total = 0;

    final dir = await _getVersionDir();
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          total += await entity.length();
        }
      }
    }

    // Also count binaries in exec dir
    try {
      final execBinDir = await _getExecBinDir();
      final execDir = Directory(execBinDir);
      if (await execDir.exists()) {
        await for (final entity in execDir.list()) {
          if (entity is File && entity.path.contains('zrok_v')) {
            total += await entity.length();
          }
        }
      }
    } catch (_) {}

    return total;
  }
}
