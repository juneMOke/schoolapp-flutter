import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:school_app_flutter/features/academic_year/data/models/academic_year_model.dart';

class AcademicYearStorageService {
  static const String _academicYearKey = 'academic_year';
  
  final FlutterSecureStorage _storage;

  const AcademicYearStorageService(this._storage);

  Future<void> saveAcademicYear(AcademicYearModel academicYear) async {
    final jsonString = jsonEncode(academicYear.toJson());
    await _storage.write(
      key: _academicYearKey,
      value: jsonString,
    );
  }

  Future<AcademicYearModel?> readAcademicYear() async {
    final jsonString = await _storage.read(key: _academicYearKey);
    if (jsonString == null) return null;

    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      return AcademicYearModel.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearAcademicYear() async {
    await _storage.delete(key: _academicYearKey);
  }
}