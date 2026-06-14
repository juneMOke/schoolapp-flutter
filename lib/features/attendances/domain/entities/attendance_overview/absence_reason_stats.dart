import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';

/// Repartition des absences par motif.
///
/// [reason] peut etre null cote backend (absence sans motif renseigne) ;
/// elle est alors consideree comme injustifiee (cf. [AbsenceReasonX]).
class AbsenceReasonStats extends Equatable {
  final AbsenceReason? reason;
  final int absenceDays;

  const AbsenceReasonStats({required this.reason, required this.absenceDays});

  @override
  List<Object?> get props => [reason, absenceDays];
}
