import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:school_app_flutter/features/bootstrap/data/models/bootstrap_model.dart';

class BootstrapStorageService {
  final Box<String> _box;

  const BootstrapStorageService(this._box);

  Future<void> saveBootstrap(BootstrapModel model, String key) async {
    await _box.put(key, jsonEncode(model.toJson()));
  }

  Future<BootstrapModel?> readBootstrap(String key) async {
    final value = _box.get(key);
    if (value == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return BootstrapModel.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearBootstrap(String key) async {
    await _box.delete(key);
  }
}
