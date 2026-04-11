import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/services/bootstrap_storage_service.dart';

abstract class BootstrapLocalDataSource {
  Future<BootstrapModel?> readBootstrap(String key);

  Future<void> saveBootstrap(BootstrapModel model, String key);

  Future<void> clearBootstrap(String key);
}

class BootstrapLocalDataSourceImpl implements BootstrapLocalDataSource {
  final BootstrapStorageService _storageService;

  const BootstrapLocalDataSourceImpl(this._storageService);

  @override
  Future<BootstrapModel?> readBootstrap(String key) async {
    return await _storageService.readBootstrap(key);
  }

  @override
  Future<void> saveBootstrap(BootstrapModel model, String key) async {
    await _storageService.saveBootstrap(model, key);
  }

  @override
  Future<void> clearBootstrap(String key) async {
    await _storageService.clearBootstrap(key);
  }
}
