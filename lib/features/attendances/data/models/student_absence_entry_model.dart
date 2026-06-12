import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_absence_entry.dart';

part 'student_absence_entry_model.g.dart';

@JsonSerializable()
class StudentAbsenceEntryModel extends Equatable {
  @JsonKey(
    fromJson: DateOnlyJsonHelper.fromJson,
    toJson: DateOnlyJsonHelper.toJson,
  )
  final DateTime date;
  final String? reason;
  final String? reasonNote;

  const StudentAbsenceEntryModel({
    required this.date,
    this.reason,
    this.reasonNote,
  });

  factory StudentAbsenceEntryModel.fromJson(Map<String, dynamic> json) =>
      _$StudentAbsenceEntryModelFromJson(json);

  Map<String, dynamic> toJson() => _$StudentAbsenceEntryModelToJson(this);

  StudentAbsenceEntry toEntity() => StudentAbsenceEntry(
    date: date,
    reason: AbsenceReasonX.fromApiValue(reason),
    reasonNote: reasonNote,
  );

  @override
  List<Object?> get props => [date, reason, reasonNote];
}
