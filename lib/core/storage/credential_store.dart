import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class CredentialStore {
  Future<void> write(String serverId, String credential);
  Future<String?> read(String serverId);
  Future<void> remove(String serverId);
}

final class PlatformCredentialStore implements CredentialStore {
  const PlatformCredentialStore({this.storage = const FlutterSecureStorage()});

  final FlutterSecureStorage storage;
  String _key(String serverId) => 'homeplace.device.$serverId';

  @override
  Future<void> write(String serverId, String credential) => storage.write(
    key: _key(serverId),
    value: credential,
    aOptions: const AndroidOptions(),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read(String serverId) => storage.read(
    key: _key(serverId),
    aOptions: const AndroidOptions(),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<void> remove(String serverId) => storage.delete(
    key: _key(serverId),
    aOptions: const AndroidOptions(),
    iOptions: const IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
}
