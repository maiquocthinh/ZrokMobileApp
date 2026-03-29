import '../../../core/infrastructure/platform/version_service.dart';
import '../../../core/infrastructure/storage/local_storage_data_source.dart';
import '../domain/entities/zrok_version.dart';
import '../domain/repositories/version_repository.dart';

class VersionRepositoryImpl implements VersionRepository {
  VersionRepositoryImpl({
    required LocalStorageDataSource storage,
    required VersionPlatformService versionService,
  }) : _storage = storage,
       _versionService = versionService;

  final LocalStorageDataSource _storage;
  final VersionPlatformService _versionService;

  @override
  Future<List<ZrokVersion>> loadVersions() async {
    return _storage.loadVersions();
  }

  @override
  Future<void> saveVersions(List<ZrokVersion> versions) {
    return _storage.saveVersions(versions);
  }

  @override
  Future<List<ZrokVersion>> fetchRemoteVersions() {
    return _versionService.fetchRemoteVersions();
  }

  @override
  Stream<double> downloadVersion(ZrokVersion version) {
    return _versionService.downloadVersion(version);
  }

  @override
  Future<void> deleteVersion(ZrokVersion version) {
    return _versionService.deleteVersion(version);
  }

  @override
  Future<void> syncLocalState(List<ZrokVersion> versions) {
    return _versionService.syncLocalState(versions);
  }

  @override
  Future<String?> getLocalPath(String versionTag) {
    return _versionService.getLocalPath(versionTag);
  }

  @override
  Future<int> getStorageUsed() {
    return _versionService.getStorageUsed();
  }
}
