import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_model.dart';
import 'package:school_app_flutter/features/bootstrap/data/services/bootstrap_storage_service.dart';

abstract class BootstrapLocalDataSource {
  Future<BootstrapModel?> readBootstrap();
  Future<void> saveBootstrap(BootstrapModel model);
  Future<void> clearBootstrap();
}

class BootstrapLocalDataSourceImpl implements BootstrapLocalDataSource {
  final BootstrapStorageService _storageService;

  const BootstrapLocalDataSourceImpl(this._storageService);

  @override
  Future<BootstrapModel?> readBootstrap() async {
    return await _storageService.readBootstrap();
  }

  @override
  Future<void> saveBootstrap(BootstrapModel model) async {
    await _storageService.saveBootstrap(model);
  }

  @override
  Future<void> clearBootstrap() async {
    await _storageService.clearBootstrap();
  }
}
