import '../entities/zrok_version.dart';

abstract class VersionRepository {
  Future<List<ZrokVersion>> loadVersions();
  Future<void> saveVersions(List<ZrokVersion> versions);

  Future<List<ZrokVersion>> fetchRemoteVersions();
  Stream<double> downloadVersion(ZrokVersion version);
  Future<void> deleteVersion(ZrokVersion version);
  Future<void> syncLocalState(List<ZrokVersion> versions);
  Future<String?> getLocalPath(String versionTag);
  Future<int> getStorageUsed();
}
