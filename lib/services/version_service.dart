import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/zrok_version.dart';

class VersionService {
  static const _apiUrl = 'https://api.github.com/repos/openziti/zrok/releases';
  static const _versionDir = 'zrok_versions';

  /// The binary name inside the tarball.
  /// zrok v2.0.0+ renamed the binary from 'zrok' to 'zrok2'.
  static const _binaryName = 'zrok2';

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

  /// Download and extract zrok binary from .tar.gz release.
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
        // Download progress is 0.0 — 0.9 (save 0.1 for extraction)
        yield (receivedBytes / totalBytes) * 0.9;
      }
    }
    await sink.close();

    // Step 2: Extract the binary from tar.gz
    // Use 'tar' command (available on Android via toybox/toolbox)
    try {
      final tarResult = await Process.run(
        'tar',
        ['xzf', archivePath, '-C', versionDir.path],
      );

      if (tarResult.exitCode != 0) {
        // Fallback: try using gzip + tar separately
        final gzResult = await Process.run(
          'gzip',
          ['-d', '-k', archivePath],
        );
        if (gzResult.exitCode == 0) {
          final tarOnlyPath = archivePath.replaceAll('.gz', '');
          await Process.run(
            'tar',
            ['xf', tarOnlyPath, '-C', versionDir.path],
          );
          // Clean up .tar file
          try { await File(tarOnlyPath).delete(); } catch (_) {}
        }
      }
    } catch (e) {
      // If tar fails, try manual extraction using dart:io GZipCodec
      await _manualExtract(archivePath, versionDir.path);
    }

    // Clean up the archive
    try { await archiveFile.delete(); } catch (_) {}

    // Step 3: Find the binary (could be 'zrok' or 'zrok2')
    String? binaryPath;
    for (final name in [_binaryName, 'zrok']) {
      final candidate = File('${versionDir.path}/$name');
      if (await candidate.exists()) {
        binaryPath = candidate.path;
        break;
      }
    }

    if (binaryPath == null) {
      // Search recursively for the binary
      await for (final entity in versionDir.list(recursive: true)) {
        if (entity is File) {
          final basename = entity.path.split('/').last;
          if (basename == _binaryName || basename == 'zrok') {
            binaryPath = entity.path;
            break;
          }
        }
      }
    }

    if (binaryPath != null) {
      // Make executable
      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', binaryPath]);
      }
      version.localPath = binaryPath;
      version.isDownloaded = true;
    }

    yield 1.0;
  }

  /// Manual tar.gz extraction fallback using dart:io
  Future<void> _manualExtract(String archivePath, String destDir) async {
    final bytes = await File(archivePath).readAsBytes();
    final decompressed = gzip.decode(bytes);

    // Parse tar format (simplified — only handles regular files)
    var offset = 0;
    while (offset < decompressed.length) {
      // Read 512-byte header
      if (offset + 512 > decompressed.length) break;
      final header = decompressed.sublist(offset, offset + 512);

      // Check for end-of-archive (two zero blocks)
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

      offset += 512; // Move past header

      if ((typeFlag == 48 || typeFlag == 0) && name.isNotEmpty && fileSize > 0) {
        // Regular file — extract it
        final fileData = decompressed.sublist(offset, offset + fileSize);
        final outPath = '$destDir/${name.split('/').last}';
        await File(outPath).writeAsBytes(fileData);
      }

      // Move past file data (padded to 512-byte blocks)
      offset += ((fileSize + 511) ~/ 512) * 512;
    }
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
      // Check both 'zrok2' (v2+) and 'zrok' (v1) binary names
      for (final name in [_binaryName, 'zrok']) {
        final binaryPath = '${dir.path}/v${version.version}/$name';
        final file = File(binaryPath);
        if (await file.exists()) {
          version.localPath = binaryPath;
          version.isDownloaded = true;
          break;
        }
      }
    }
  }

  /// Get local binary path for a version.
  Future<String?> getLocalPath(String versionTag) async {
    final dir = await _getVersionDir();
    // Check both binary names
    for (final name in [_binaryName, 'zrok']) {
      final binaryPath = '${dir.path}/v$versionTag/$name';
      final file = File(binaryPath);
      if (await file.exists()) return binaryPath;
    }
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
