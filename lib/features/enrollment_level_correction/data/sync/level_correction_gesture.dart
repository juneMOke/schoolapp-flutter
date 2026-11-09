import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:school_app_flutter/core/offline/outbox_author.dart';

/// Une correction de niveau telle qu'elle est figée dans l'outbox : un élève,
/// un geste, une requête.
///
/// La tablette envoie un **fait** (« cet élève passe de tel niveau à tel
/// autre ») ; c'est le serveur qui recalcule ce qui est dû. Aucun montant ne
/// part donc sur le fil.
///
/// [id] est l'uuid du geste, fabriqué par la tablette : c'est la clé
/// d'idempotence serveur (201 appliqué, 200 rejeu). [fromSchoolLevelId] arme la
/// garde `STALE_LEVEL` : une seconde tablette qui corrigerait sur une copie
/// périmée est refusée au lieu d'écraser la première.
///
/// [studentId] et [academicYearId] ne partent pas sur le fil : ils servent la
/// sonde de dépendance (inscription accusée) et la garde du guichet.
class LevelCorrectionGesture extends Equatable {
  final String id;
  final String enrollmentId;
  final String studentId;
  final String academicYearId;
  final String fromSchoolLevelId;
  final String toSchoolLevelId;
  final String toSchoolLevelGroupId;

  /// Classe cible, `null` quand l'élève n'est pas en classe ou que le niveau
  /// cible n'en a aucune (D3).
  final String? toClassroomId;

  /// Motif libre, obligatoire.
  final String reason;

  /// Instant du geste sur la tablette, ISO-8601 UTC à la milliseconde.
  final String correctedAt;
  final String authorId;

  const LevelCorrectionGesture({
    required this.id,
    required this.enrollmentId,
    required this.studentId,
    required this.academicYearId,
    required this.fromSchoolLevelId,
    required this.toSchoolLevelId,
    required this.toSchoolLevelGroupId,
    required this.reason,
    required this.correctedAt,
    required this.authorId,
    this.toClassroomId,
  });

  /// Le corps de la requête : le fait sous sa clé, l'auteur à côté — le patron
  /// de la désactivation d'élèves.
  Map<String, Object?> toWire() => {
    'correction': {
      'id': id,
      'enrollmentId': enrollmentId,
      'fromSchoolLevelId': fromSchoolLevelId,
      'toSchoolLevelId': toSchoolLevelId,
      'toSchoolLevelGroupId': toSchoolLevelGroupId,
      'toClassroomId': toClassroomId,
      'reason': reason,
      'correctedAt': correctedAt,
    },
    kOutboxAuthorIdKey: authorId,
  };

  /// La forme rangée dans l'outbox. [kOutboxAuthorIdKey] y figure à la racine,
  /// là où le socle lit l'auteur d'une entrée.
  Map<String, Object?> toJson() => {
    'id': id,
    'enrollmentId': enrollmentId,
    'studentId': studentId,
    'academicYearId': academicYearId,
    'fromSchoolLevelId': fromSchoolLevelId,
    'toSchoolLevelId': toSchoolLevelId,
    'toSchoolLevelGroupId': toSchoolLevelGroupId,
    'toClassroomId': toClassroomId,
    'reason': reason,
    'correctedAt': correctedAt,
    kOutboxAuthorIdKey: authorId,
  };

  /// `null` si un champ obligatoire manque : l'entrée est illisible.
  static LevelCorrectionGesture? tryParse(Object? json) {
    if (json is! Map) return null;
    final id = json.text('id');
    final enrollmentId = json.text('enrollmentId');
    final studentId = json.text('studentId');
    final yearId = json.text('academicYearId');
    final fromLevel = json.text('fromSchoolLevelId');
    final toLevel = json.text('toSchoolLevelId');
    final toGroup = json.text('toSchoolLevelGroupId');
    final reason = json.text('reason');
    final at = json.text('correctedAt');
    final authorId = json.text(kOutboxAuthorIdKey);
    if (id == null ||
        enrollmentId == null ||
        studentId == null ||
        yearId == null ||
        fromLevel == null ||
        toLevel == null ||
        toGroup == null ||
        reason == null ||
        at == null ||
        authorId == null) {
      return null;
    }
    return LevelCorrectionGesture(
      id: id,
      enrollmentId: enrollmentId,
      studentId: studentId,
      academicYearId: yearId,
      fromSchoolLevelId: fromLevel,
      toSchoolLevelId: toLevel,
      toSchoolLevelGroupId: toGroup,
      toClassroomId: json.text('toClassroomId'),
      reason: reason,
      correctedAt: at,
      authorId: authorId,
    );
  }

  @override
  List<Object?> get props => [
    id,
    enrollmentId,
    studentId,
    academicYearId,
    fromSchoolLevelId,
    toSchoolLevelId,
    toSchoolLevelGroupId,
    toClassroomId,
    reason,
    correctedAt,
    authorId,
  ];
}
