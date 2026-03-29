import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../features/versions/domain/entities/zrok_version.dart';

class VersionPlatformService {
  static const _apiUrl =
      'https://api.github.com/repos/maiquocthinh/ZrokMobileApp/releases';
  static const _versionDir = 'zrok_versions';
  static const _channel = MethodChannel('com.zrokapp.mobile/exec');

  /// The binary name inside the tarball.
  static const _binaryNames = ['zrok2', 'zrok'];

  void _log(String msg) => debugPrint('[VersionPlatformService] $msg');

  Future<List<ZrokVersion>> fetchRemoteVersions() async {
    try {
      final versions = <ZrokVersion>[];
      var page = 1;
      const perPage = 100;

      while (true) {
        final response = await http.get(
          Uri.parse('$_apiUrl?per_page=$perPage&page=$page'),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        );
        if (response.statusCode != 200) {
          _log('GitHub API error: ${response.statusCode}');
          break;
        }

        final releases = jsonDecode(response.body) as List;
        if (releases.isEmpty) break;

        for (final release in releases) {
          // Tag format: zrok-vX.Y.Z → extract X.Y.Z
          final tagName = (release['tag_name'] as String?) ?? '';
          final versionMatch = RegExp(r'zrok-v(.+)').firstMatch(tagName);
          final version =
              versionMatch?.group(1) ?? tagName.replaceFirst('v', '');
          if (version.isEmpty) continue;

          final assets = release['assets'] as List? ?? [];
          String? downloadUrl;
          String assetName = 'libzrok.so';
          int size = 0;
          for (final asset in assets) {
            final name = (asset['name'] as String?) ?? '';
            // New format: raw binary libzrok.so
            if (name == 'libzrok.so') {
              downloadUrl = asset['browser_download_url'] as String?;
              size = asset['size'] as int? ?? 0;
              assetName = name;
              break;
            }
            // Fallback: old tar.gz format from upstream
            if (name.contains('linux') &&
                name.contains('arm64') &&
                name.endsWith('.tar.gz')) {
              downloadUrl = asset['browser_download_url'] as String?;
              size = asset['size'] as int? ?? 0;
              assetName = name;
              break;
            }
          }

          versions.add(
            ZrokVersion(
              version: version,
              downloadUrl: downloadUrl ?? '',
              assetName: assetName,
              sizeBytes: size,
              releaseDate: DateTime.tryParse(
                release['published_at'] as String? ?? '',
              ),
            ),
          );
        }

        // If fewer than perPage results, we've reached the last page
        if (releases.length < perPage) break;
        page++;
        // Safety: max 10 pages
        if (page > 10) break;
      }

      _log('Fetched ${versions.length} versions');
      return versions;
    } catch (e) {
      _log('fetchRemoteVersions error: $e');
      return [];
    }
  }

  Future<Directory> _getVersionDir() async {
    final appDir = await getApplicationSupportDirectory();
    return Directory('${appDir.path}/$_versionDir');
  }

  Future<String> _getExecBinDir() async {
    try {
      final filesDir = await _channel.invokeMethod<String>('getFilesDir');
      if (filesDir != null) {
        final binDir = Directory('$filesDir/bin');
        if (!await binDir.exists()) {
          await binDir.create(recursive: true);
        }
        _log('Exec bin dir: ${binDir.path}');
        return binDir.path;
      }
    } catch (e) {
      _log('getFilesDir error: $e');
    }
    final dir = await _getVersionDir();
    return dir.path;
  }

  /// Download, extract (if needed), chmod, and store the zrok binary.
  /// Returns a stream of progress (0.0 to 1.0).
  Stream<double> downloadVersion(ZrokVersion version) async* {
    if (version.downloadUrl.isEmpty) {
      _log('ERROR: No download URL for ${version.version}');
      return;
    }

    _log('=== Download started: v${version.version} ===');
    _log('URL: ${version.downloadUrl}');
    _log('Asset: ${version.assetName}');

    final isRawBinary = !version.assetName.endsWith('.tar.gz');

    if (isRawBinary) {
      yield* _downloadRawBinary(version);
    } else {
      yield* _downloadTarGz(version);
    }
  }

  /// Download a raw binary file (e.g., libzrok.so from our CI builds).
  Stream<double> _downloadRawBinary(ZrokVersion version) async* {
    final dir = await _getVersionDir();
    final versionDir = Directory('${dir.path}/v${version.version}');
    if (!await versionDir.exists()) {
      await versionDir.create(recursive: true);
    }

    final binaryPath = '${versionDir.path}/zrok2';
    _log('Downloading raw binary to: $binaryPath');

    // Step 1: Download
    final request = http.Request('GET', Uri.parse(version.downloadUrl));
    final response = await http.Client().send(request);
    _log(
      'HTTP status: ${response.statusCode}, content-length: ${response.contentLength}',
    );

    final totalBytes = response.contentLength ?? version.sizeBytes;
    var receivedBytes = 0;

    final binaryFile = File(binaryPath);
    final sink = binaryFile.openWrite();

    await for (final chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        yield (receivedBytes / totalBytes) * 0.9;
      }
    }
    await sink.close();

    final fileSize = await binaryFile.length();
    _log('Downloaded: $receivedBytes bytes, file size: $fileSize');
    yield 0.92;

    // Step 2: Set executable permissions
    await _makeExecutable(binaryPath);
    yield 0.95;

    // Step 3: Copy to exec dir
    final finalPath = await _copyToExecDir(binaryPath, version.version);

    version.localPath = finalPath ?? binaryPath;
    version.isDownloaded = true;
    _log('=== Download complete: ${version.localPath} ===');
    yield 1.0;
  }

  /// Download a .tar.gz archive (fallback for old upstream releases).
  Stream<double> _downloadTarGz(ZrokVersion version) async* {
    final dir = await _getVersionDir();
    final versionDir = Directory('${dir.path}/v${version.version}');
    if (!await versionDir.exists()) {
      await versionDir.create(recursive: true);
    }
    _log('Version dir: ${versionDir.path}');

    // Step 1: Download the .tar.gz archive
    final archivePath = '${versionDir.path}/zrok.tar.gz';
    _log('Downloading to: $archivePath');

    final request = http.Request('GET', Uri.parse(version.downloadUrl));
    final response = await http.Client().send(request);
    _log(
      'HTTP status: ${response.statusCode}, content-length: ${response.contentLength}',
    );

    final totalBytes = response.contentLength ?? version.sizeBytes;
    var receivedBytes = 0;

    final archiveFile = File(archivePath);
    final sink = archiveFile.openWrite();

    await for (final chunk in response.stream) {
      sink.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        yield (receivedBytes / totalBytes) * 0.8;
      }
    }
    await sink.close();

    final archiveSize = await archiveFile.length();
    _log('Downloaded: $receivedBytes bytes, file size: $archiveSize');
    yield 0.85;

    // Step 2: Extract the binary from tar.gz
    _log('Extracting...');
    bool tarSucceeded = false;
    try {
      final tarResult = await Process.run('tar', [
        'xzf',
        archivePath,
        '-C',
        versionDir.path,
      ]);
      _log('tar exit: ${tarResult.exitCode}');
      if (tarResult.stderr.toString().isNotEmpty) {
        _log('tar stderr: ${tarResult.stderr}');
      }
      tarSucceeded = tarResult.exitCode == 0;
    } catch (e) {
      _log('tar command error: $e');
    }

    if (!tarSucceeded) {
      _log('tar failed, trying manual extraction...');
      try {
        await _manualExtract(archivePath, versionDir.path);
        _log('Manual extraction completed');
      } catch (e) {
        _log('Manual extraction FAILED: $e');
      }
    }

    // Clean up archive
    try {
      await archiveFile.delete();
    } catch (_) {}
    yield 0.90;

    // Step 3: Find the extracted binary
    String? extractedPath;
    for (final name in _binaryNames) {
      final candidate = File('${versionDir.path}/$name');
      if (await candidate.exists()) {
        extractedPath = candidate.path;
        _log('Found binary at root: $extractedPath');
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
            _log('Found binary recursively: $extractedPath');
            break;
          }
        }
      }
    }

    yield 0.95;

    if (extractedPath == null) {
      _log('ERROR: No binary found after extraction!');
      yield 1.0;
      return;
    }

    // Step 4: Set executable permissions + copy
    await _makeExecutable(extractedPath);
    final finalPath = await _copyToExecDir(extractedPath, version.version);

    version.localPath = finalPath ?? extractedPath;
    version.isDownloaded = true;
    _log('=== Download complete: ${version.localPath} ===');
    yield 1.0;
  }

  /// Set executable permissions on a file.
  Future<void> _makeExecutable(String path) async {
    _log('Setting executable permissions on: $path');

    // Method 1: Native Android API
    bool chmodOk = false;
    try {
      final result = await _channel.invokeMethod<bool>('makeExecutable', {
        'path': path,
      });
      chmodOk = result == true;
      _log('Native makeExecutable: $chmodOk');
    } catch (e) {
      _log('Native makeExecutable error: $e');
    }

    // Method 2: chmod command
    if (!chmodOk) {
      try {
        final result = await Process.run('chmod', ['755', path]);
        _log('chmod 755 exit: ${result.exitCode}');
        if (result.exitCode == 0) chmodOk = true;
      } catch (e) {
        _log('chmod command error: $e');
      }
    }

    // Verify
    final stat = await File(path).stat();
    _log(
      '  size: ${stat.size} bytes, mode: ${stat.mode.toRadixString(8)}, chmod ok: $chmodOk',
    );
  }

  /// Copy binary to the exec bin dir. Returns the new path, or null on failure.
  Future<String?> _copyToExecDir(String srcPath, String version) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'copyToExecutableDir',
        {'srcPath': srcPath, 'destName': 'zrok_v$version'},
      );
      if (result != null) {
        _log('Copy to exec dir: $result');
        return result;
      }
    } catch (e) {
      _log('Copy to exec dir error: $e');
    }
    return null;
  }

  /// Manual tar.gz extraction fallback using dart:io
  Future<void> _manualExtract(String archivePath, String destDir) async {
    _log('Manual extract: $archivePath -> $destDir');
    final bytes = await File(archivePath).readAsBytes();
    _log('Archive size: ${bytes.length} bytes');

    final decompressed = gzip.decode(bytes);
    _log('Decompressed size: ${decompressed.length} bytes');

    var offset = 0;
    var fileCount = 0;
    while (offset < decompressed.length) {
      if (offset + 512 > decompressed.length) break;
      final header = decompressed.sublist(offset, offset + 512);

      if (header.every((b) => b == 0)) break;

      final nameBytes = header.sublist(0, 100);
      final nameEnd = nameBytes.indexOf(0);
      final name = utf8
          .decode(nameBytes.sublist(0, nameEnd > 0 ? nameEnd : 100))
          .trim();

      final sizeStr = utf8
          .decode(header.sublist(124, 136))
          .trim()
          .replaceAll('\x00', '');
      final fileSize = sizeStr.isNotEmpty
          ? int.tryParse(sizeStr, radix: 8) ?? 0
          : 0;

      final typeFlag = header[156];
      offset += 512;

      if ((typeFlag == 48 || typeFlag == 0) &&
          name.isNotEmpty &&
          fileSize > 0) {
        final fileData = decompressed.sublist(offset, offset + fileSize);
        // Use just the filename (strip directory prefix)
        final baseName = name.split('/').last;
        if (baseName.isNotEmpty) {
          final outPath = '$destDir/$baseName';
          await File(outPath).writeAsBytes(fileData);
          _log('  Extracted: $baseName ($fileSize bytes)');
          fileCount++;
        }
      }

      offset += ((fileSize + 511) ~/ 512) * 512;
    }
    _log('Manual extract: $fileCount files extracted');
  }

  Future<void> deleteVersion(ZrokVersion version) async {
    if (version.localPath != null) {
      try {
        final file = File(version.localPath!);
        if (await file.exists()) await file.delete();
      } catch (_) {}

      final dir = await _getVersionDir();
      final versionDir = Directory('${dir.path}/v${version.version}');
      try {
        if (await versionDir.exists()) await versionDir.delete(recursive: true);
      } catch (_) {}

      version.localPath = null;
      version.isDownloaded = false;
    }
  }

  Future<void> syncLocalState(List<ZrokVersion> versions) async {
    final dir = await _getVersionDir();
    String? execBinDir;
    try {
      execBinDir = await _getExecBinDir();
    } catch (_) {}

    for (final version in versions) {
      if (execBinDir != null) {
        final execPath = '$execBinDir/zrok_v${version.version}';
        if (await File(execPath).exists()) {
          version.localPath = execPath;
          version.isDownloaded = true;
          continue;
        }
      }

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

  Future<String?> getLocalPath(String versionTag) async {
    try {
      final execBinDir = await _getExecBinDir();
      final execPath = '$execBinDir/zrok_v$versionTag';
      if (await File(execPath).exists()) return execPath;
    } catch (_) {}

    final dir = await _getVersionDir();
    for (final name in _binaryNames) {
      final binaryPath = '${dir.path}/v$versionTag/$name';
      if (await File(binaryPath).exists()) return binaryPath;
    }
    return null;
  }

  Future<int> getStorageUsed() async {
    int total = 0;

    final dir = await _getVersionDir();
    if (await dir.exists()) {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) total += await entity.length();
      }
    }

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
