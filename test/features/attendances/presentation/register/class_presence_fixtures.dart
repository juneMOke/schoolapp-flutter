import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/core/presence/domain/presence_justification.dart';
import 'package:school_app_flutter/core/presence/domain/presence_mark.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_classroom.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_day.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_line.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/register/class_presence_student.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';

const kClassroom = ClassPresenceClassroom(
  id: 'c1',
  name: '6e A',
  levelName: '6ème primaire',
  studentCount: 3,
);

ClassPresenceStudent student(String id, String last, String first, int n) =>
    ClassPresenceStudent(
      id: id,
      firstName: first,
      lastName: last,
      gender: StudentGender.female,
      number: n,
    );

final grace = student('s1', 'Mbuyi', 'Grâce', 1);
final jean = student('s2', 'Ilunga', 'Jean', 2);
final esther = student('s3', 'Zola', 'Esther', 3);

ClassPresenceLine line(
  ClassPresenceStudent s,
  PresenceStatus status, {
  AbsenceReason? reason,
}) => ClassPresenceLine(
  student: s,
  mark: PresenceMark(
    status: status,
    justification: reason == null
        ? null
        : PresenceJustification(reason: reason),
  ),
  sync: RecordSyncState.synced,
);

/// Un appel : à faire (brouillon) ou validé ([validated]).
ClassPresenceDay presenceDay({
  String day = '2026-10-01',
  bool validated = false,
  bool reopened = false,
  bool monthClosed = false,
  List<ClassPresenceLine>? lines,
}) => ClassPresenceDay(
  classroomId: kClassroom.id,
  academicYearId: 'y1',
  day: day,
  lines:
      lines ??
      [
        line(grace, PresenceStatus.present),
        line(jean, PresenceStatus.absent),
        line(esther, validated ? PresenceStatus.present : PresenceStatus.none),
      ],
  hasSession: validated || reopened,
  reopened: reopened,
  schedule: PresenceSchedule.defaults,
  monthClosed: monthClosed,
);
