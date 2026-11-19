import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/weekday.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';

/// Qui a publié ou modifié : un nom (nul si le compte n'en a pas), un rôle.
class TimetableActor extends Equatable {
  final String? name;
  final String? role;

  const TimetableActor({this.name, this.role});

  static TimetableActor? fromJson(Object? raw) => raw is Map
      ? TimetableActor(
          name: raw['name'] as String?,
          role: raw['role'] as String?,
        )
      : null;

  @override
  List<Object?> get props => [name, role];
}

/// L'en-tête de l'emploi du temps d'une classe (EDT-R6) : la version publiée,
/// le brouillon ouvert, la révision que la publication renvoie.
class ClassTimetableHeader extends Equatable {
  final String id;
  final String classroomId;
  final String academicYearId;
  final int? publishedVersion;
  final DateTime? publishedAt;
  final TimetableActor? publishedBy;
  final String? draftId;
  final DateTime? draftUpdatedAt;
  final TimetableActor? draftUpdatedBy;
  final int revision;

  const ClassTimetableHeader({
    required this.id,
    required this.classroomId,
    required this.academicYearId,
    required this.revision,
    this.publishedVersion,
    this.publishedAt,
    this.publishedBy,
    this.draftId,
    this.draftUpdatedAt,
    this.draftUpdatedBy,
  });

  bool get isPublished => publishedVersion != null;

  bool get hasDraft => draftId != null;

  @override
  List<Object?> get props => [
    id,
    classroomId,
    academicYearId,
    publishedVersion,
    publishedAt,
    publishedBy,
    draftId,
    draftUpdatedAt,
    draftUpdatedBy,
    revision,
  ];
}

enum TimetableCellStatus {
  published('PUBLISHED'),
  draft('DRAFT');

  const TimetableCellStatus(this.wire);

  final String wire;

  static TimetableCellStatus fromWire(String? value) =>
      value == draft.wire ? draft : published;
}

/// Une case d'emploi du temps, publiée ou en brouillon, d'une classe.
class ClassTimetableCell extends Equatable {
  final String id;
  final String classroomId;
  final String classroomLabel;
  final TimetableCellStatus status;
  final String? draftId;
  final Weekday day;
  final String slotId;
  final MinuteRange range;
  final String? coursId;
  final String? teacherId;
  final String? subjectLabel;
  final String? teacherLabel;
  final int? clientUpdatedAtMs;
  final RecordSyncState syncState;
  final String? errorCode;
  final bool superseded;

  const ClassTimetableCell({
    required this.id,
    required this.classroomId,
    required this.classroomLabel,
    required this.status,
    required this.day,
    required this.slotId,
    required this.range,
    this.draftId,
    this.coursId,
    this.teacherId,
    this.subjectLabel,
    this.teacherLabel,
    this.clientUpdatedAtMs,
    this.syncState = RecordSyncState.synced,
    this.errorCode,
    this.superseded = false,
  });

  bool get isEmpty => coursId == null;

  /// L'id stable d'une case (le même que le serveur, pour une case posée ici).
  static String keyOf({
    required String classroomId,
    required TimetableCellStatus status,
    required String? draftId,
    required Weekday day,
    required String slotId,
  }) => '${status.wire}:$classroomId:${draftId ?? '-'}:${day.wire}:$slotId';

  @override
  List<Object?> get props => [
    id,
    classroomId,
    classroomLabel,
    status,
    draftId,
    day,
    slotId,
    range,
    coursId,
    teacherId,
    subjectLabel,
    teacherLabel,
    clientUpdatedAtMs,
    syncState,
    errorCode,
    superseded,
  ];
}

/// Un cours du programme d'une classe (bundle `schedule.programmes`).
class TimetableCourse extends Equatable {
  final String coursId;
  final String classroomId;
  final String branchId;
  final String branchLabel;
  final String? domainId;
  final String? domainLabel;
  final int? domainOrder;
  final String? teacherId;
  final String? teacherLabel;
  final int? weeklyHours;

  const TimetableCourse({
    required this.coursId,
    required this.classroomId,
    required this.branchId,
    required this.branchLabel,
    this.domainId,
    this.domainLabel,
    this.domainOrder,
    this.teacherId,
    this.teacherLabel,
    this.weeklyHours,
  });

  @override
  List<Object?> get props => [
    coursId,
    classroomId,
    branchId,
    branchLabel,
    domainId,
    domainLabel,
    domainOrder,
    teacherId,
    teacherLabel,
    weeklyHours,
  ];
}
