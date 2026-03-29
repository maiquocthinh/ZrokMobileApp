import '../entities/env_info.dart';

abstract class EnvironmentRepository {
  Future<List<EnvInfo>> loadEnvironments();
  Future<void> saveEnvironments(List<EnvInfo> environments);

  Future<void> saveToken(String envId, String token);
  Future<String?> readToken(String envId);
  Future<void> deleteToken(String envId);
}
