import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';

/// Une absence ponctuelle dans le resume de presence d'un eleve.
class StudentAbsenceEntry extends Equatable {
  final DateTime date;
  final AbsenceReason? reason;
  final String? reasonNote;

  const StudentAbsenceEntry({required this.date, this.reason, this.reasonNote});

  @override
  List<Object?> get props => [date, reason, reasonNote];
}
