import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:school_app_flutter/core/offline/keyset_page.dart';

/// L'état d'une photo côté serveur — une ligne du flux `student.photos`, et ce
/// que rendent les deux écritures.
///
/// [sha256] `null` = pas de photo : retirée, ou jamais prise.
class StudentPhotoStateDto {
  final String studentId;
  final String? sha256;
  final String? takenAt;
  final String? serverUpdatedAt;

  const StudentPhotoStateDto({
    required this.studentId,
    this.sha256,
    this.takenAt,
    this.serverUpdatedAt,
  });

  static StudentPhotoStateDto? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final studentId = raw.text('studentId');
    if (studentId == null) return null;
    final sha256 = raw.text('sha256')?.toLowerCase();
    return StudentPhotoStateDto(
      studentId: studentId,
      sha256: sha256,
      takenAt: raw.instant('takenAt'),
      serverUpdatedAt: raw.instant('serverUpdatedAt'),
    );
  }

  /// L'accusé d'une écriture : l'état courant, nu ou sous `photo`.
  static StudentPhotoStateDto parseAck(Object? json) {
    final body = json is Map && json['photo'] is Map ? json['photo'] : json;
    final state = tryParse(body);
    if (state == null) {
      throw const FormatException('Accusé de photo illisible');
    }
    return state;
  }
}

/// Page du flux `student.photos`.
class StudentPhotoPageDto extends ParsedKeysetPage<StudentPhotoStateDto> {
  StudentPhotoPageDto._(ParsedKeysetPage<StudentPhotoStateDto> parsed)
    : super(items: parsed.items, page: parsed.page, skipped: parsed.skipped);

  factory StudentPhotoPageDto.fromJson(Map<String, dynamic> json) =>
      StudentPhotoPageDto._(
        ParsedKeysetPage.fromJson(json, StudentPhotoStateDto.tryParse),
      );
}
