import '../../../core/infrastructure/storage/local_storage_data_source.dart';
import '../../../core/infrastructure/storage/secure_token_store.dart';
import '../domain/entities/env_info.dart';
import '../domain/repositories/environment_repository.dart';

class EnvironmentRepositoryImpl implements EnvironmentRepository {
  EnvironmentRepositoryImpl({
    required LocalStorageDataSource storage,
    required SecureTokenStore secureTokenStore,
  }) : _storage = storage,
       _secureTokenStore = secureTokenStore;

  final LocalStorageDataSource _storage;
  final SecureTokenStore _secureTokenStore;

  @override
  Future<List<EnvInfo>> loadEnvironments() async {
    return _storage.loadEnvironments();
  }

  @override
  Future<void> saveEnvironments(List<EnvInfo> environments) {
    return _storage.saveEnvironments(environments);
  }

  @override
  Future<void> saveToken(String envId, String token) {
    return _secureTokenStore.saveToken(envId, token);
  }

  @override
  Future<String?> readToken(String envId) {
    return _secureTokenStore.readToken(envId);
  }

  @override
  Future<void> deleteToken(String envId) {
    return _secureTokenStore.deleteToken(envId);
  }
}
