import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_model.dart';

class BootstrapLocalMigrationService {
  final FlutterSecureStorage _legacyStorage;
  final Box<String> _bootstrapBox;

  const BootstrapLocalMigrationService({
    required FlutterSecureStorage legacyStorage,
    required Box<String> bootstrapBox,
  }) : _legacyStorage = legacyStorage,
       _bootstrapBox = bootstrapBox;

  Future<void> migrateIfNeeded() async {
    final currentVersion = await _legacyStorage.read(
      key: AppConstants.bootstrapSchemaVersionKey,
    );

    if (currentVersion == AppConstants.bootstrapSchemaVersion) {
      return;
    }

    final hivePayload = _bootstrapBox.get(AppConstants.bootstrapPayloadKey);
    if (hivePayload != null && hivePayload.isNotEmpty) {
      await _markMigrationDone();
      await _clearLegacyPayload();
      return;
    }

    final legacyPayload = await _legacyStorage.read(
      key: AppConstants.bootstrapPayloadKey,
    );

    if (legacyPayload == null || legacyPayload.isEmpty) {
      await _markMigrationDone();
      return;
    }

    try {
      final decoded = jsonDecode(legacyPayload) as Map<String, dynamic>;
      final model = BootstrapModel.fromJson(decoded);
      await _bootstrapBox.put(
        AppConstants.bootstrapPayloadKey,
        jsonEncode(model.toJson()),
      );
      await _clearLegacyPayload();
      await _markMigrationDone();
    } catch (_) {
      // Keep legacy payload untouched to allow future retry after app update.
    }
  }

  Future<void> _markMigrationDone() {
    return _legacyStorage.write(
      key: AppConstants.bootstrapSchemaVersionKey,
      value: AppConstants.bootstrapSchemaVersion,
    );
  }

  Future<void> _clearLegacyPayload() {
    return _legacyStorage.delete(key: AppConstants.bootstrapPayloadKey);
  }
}
