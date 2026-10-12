import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/audience_student.dart';

/// Les sélections de **tous** les modes de ciblage, tenues ensemble : passer
/// de « Classes » à « Élèves » puis revenir ne perd rien. Seul le mode actif
/// part sur le fil ([audience]).
class AudienceSelections extends Equatable {
  final AudienceMode mode;
  final List<String> levelIds;
  final List<String> classroomIds;
  final List<AudienceStudent> students;
  final String? feeCode;
  final String? tariffCode;
  final int overdueDays;

  const AudienceSelections({
    this.mode = AudienceMode.school,
    this.levelIds = const [],
    this.classroomIds = const [],
    this.students = const [],
    this.feeCode,
    this.tariffCode,
    this.overdueDays = 0,
  });

  /// Les sélections d'une audience reçue : seul son mode est renseigné.
  factory AudienceSelections.of(AnnouncementAudience audience) =>
      switch (audience) {
        SchoolAudience() => const AudienceSelections(),
        LevelsAudience(:final levelIds) => AudienceSelections(
          mode: AudienceMode.levels,
          levelIds: levelIds,
        ),
        ClassroomsAudience(:final classroomIds) => AudienceSelections(
          mode: AudienceMode.classrooms,
          classroomIds: classroomIds,
        ),
        StudentsAudience(:final studentIds) => AudienceSelections(
          mode: AudienceMode.students,
          students: [
            for (final id in studentIds)
              audience.studentOf(id) ?? AudienceStudent(id: id, lastName: ''),
          ],
        ),
        OverdueAudience(
          :final feeCode,
          :final tariffCode,
          :final overdueDays,
        ) =>
          AudienceSelections(
            mode: AudienceMode.overdue,
            feeCode: feeCode,
            tariffCode: tariffCode,
            overdueDays: overdueDays,
          ),
      };

  /// L'audience du mode actif.
  AnnouncementAudience get audience => switch (mode) {
    AudienceMode.school => const SchoolAudience(),
    AudienceMode.levels => LevelsAudience(levelIds),
    AudienceMode.classrooms => ClassroomsAudience(classroomIds),
    AudienceMode.students => StudentsAudience(students),
    AudienceMode.overdue => OverdueAudience(
      feeCode: feeCode,
      tariffCode: feeCode == null ? null : tariffCode,
      overdueDays: overdueDays,
    ),
  };

  AudienceSelections withMode(AudienceMode mode) => _copy(mode: mode);

  AudienceSelections toggleLevel(String id) =>
      _copy(levelIds: _toggled(levelIds, id));

  AudienceSelections toggleClassroom(String id) =>
      _copy(classroomIds: _toggled(classroomIds, id));

  /// Toutes les classes d'un niveau d'un coup : cochées si l'une manquait,
  /// toutes décochées sinon.
  AudienceSelections toggleClassrooms(List<String> ids) {
    final all = ids.every(classroomIds.contains);
    return _copy(
      classroomIds: all
          ? [
              for (final id in classroomIds)
                if (!ids.contains(id)) id,
            ]
          : [
              ...classroomIds,
              for (final id in ids)
                if (!classroomIds.contains(id)) id,
            ],
    );
  }

  AudienceSelections addStudent(AudienceStudent student) =>
      students.any((s) => s.id == student.id)
      ? this
      : _copy(students: [...students, student]);

  AudienceSelections removeStudent(String id) => _copy(
    students: [
      for (final s in students)
        if (s.id != id) s,
    ],
  );

  /// Une autre nature remet la tranche à « toutes ».
  AudienceSelections withFee(String? feeCode, {String? tariffCode}) =>
      AudienceSelections(
        mode: mode,
        levelIds: levelIds,
        classroomIds: classroomIds,
        students: students,
        feeCode: feeCode,
        tariffCode: feeCode == null ? null : tariffCode,
        overdueDays: overdueDays,
      );

  AudienceSelections withOverdueDays(int days) => _copy(overdueDays: days);

  AudienceSelections _copy({
    AudienceMode? mode,
    List<String>? levelIds,
    List<String>? classroomIds,
    List<AudienceStudent>? students,
    int? overdueDays,
  }) => AudienceSelections(
    mode: mode ?? this.mode,
    levelIds: levelIds ?? this.levelIds,
    classroomIds: classroomIds ?? this.classroomIds,
    students: students ?? this.students,
    feeCode: feeCode,
    tariffCode: tariffCode,
    overdueDays: overdueDays ?? this.overdueDays,
  );

  static List<String> _toggled(List<String> ids, String id) => ids.contains(id)
      ? [
          for (final other in ids)
            if (other != id) other,
        ]
      : [...ids, id];

  @override
  List<Object?> get props => [
    mode,
    levelIds,
    classroomIds,
    students,
    feeCode,
    tariffCode,
    overdueDays,
  ];
}
