import 'package:school_app_flutter/core/helpers/json_fields.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_student.dart';

/// L'audience sur le fil : une union discriminée par `mode`.
abstract final class AudienceWire {
  static Map<String, Object?> toJson(AnnouncementAudience audience) => {
    'mode': audience.mode.wire,
    ...switch (audience) {
      SchoolAudience() => const <String, Object?>{},
      LevelsAudience(:final levelIds) => {'levelIds': levelIds},
      ClassroomsAudience(:final classroomIds) => {'classroomIds': classroomIds},
      StudentsAudience(:final studentIds) => {'studentIds': studentIds},
      OverdueAudience(:final feeCode, :final tariffCode, :final overdueDays) =>
        {
          'feeCode': feeCode,
          'tariffCode': tariffCode,
          'overdueDays': overdueDays,
        },
    },
  };

  /// `null` pour un mode inconnu : le communiqué qui le porte est écarté.
  static AnnouncementAudience? fromJson(Object? raw) {
    if (raw is! Map) return null;
    return switch (AudienceMode.fromWire(raw.text('mode'))) {
      AudienceMode.school => const SchoolAudience(),
      AudienceMode.levels => LevelsAudience(raw.texts('levelIds')),
      AudienceMode.classrooms => ClassroomsAudience(raw.texts('classroomIds')),
      AudienceMode.students => _students(raw),
      AudienceMode.overdue => _overdue(raw),
      null => null,
    };
  }

  /// Les noms rendus avec l'audience, quand le serveur les donne ; sinon les
  /// seuls identifiants.
  static StudentsAudience _students(Map<dynamic, dynamic> raw) {
    final students = raw['students'];
    final known = [
      if (students is List)
        for (final item in students) ?studentOf(item),
    ];
    return known.isEmpty
        ? StudentsAudience.ids(raw.texts('studentIds'))
        : StudentsAudience(known);
  }

  static OverdueAudience _overdue(Map<dynamic, dynamic> raw) {
    final feeCode = raw.text('feeCode');
    return OverdueAudience(
      feeCode: feeCode,
      tariffCode: feeCode == null ? null : raw.text('tariffCode'),
      overdueDays: raw.integer('overdueDays') ?? 0,
    );
  }

  /// Un élève de la recherche (`AnnouncementStudentHit`) : nom en trois
  /// parties — le post-nom s'appelle `surname` sur le fil —, et sa classe,
  /// sinon son niveau. Sans identifiant ni nom, il est écarté.
  static AudienceStudent? studentOf(Object? raw) {
    if (raw is! Map) return null;
    final id = raw.text('id');
    final lastName = raw.text('lastName');
    if (id == null || lastName == null) return null;
    return AudienceStudent(
      id: id,
      lastName: lastName,
      middleName: raw.text('surname'),
      firstName: raw.text('firstName'),
      classroomLabel: raw.text('classroomName') ?? raw.text('levelName'),
    );
  }
}
