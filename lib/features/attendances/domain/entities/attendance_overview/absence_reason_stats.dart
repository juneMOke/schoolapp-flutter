import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';

/// Repartition des absences par motif.
///
/// [reason] peut être `null` côté backend (absence sans motif renseigné) ; elle
/// est alors considérée comme injustifiée — verdict rendu par
/// [isUnjustifiedAbsence].
///
/// ⚠️ Cette docstring renvoyait auparavant à `AbsenceReasonX`, dont le getter
/// ne traitait pas `null` du tout : elle décrivait un comportement que le code
/// désigné n'avait pas. C'est la fonction ci-dessus qui le porte désormais, et
/// elle prend un motif nullable précisément pour ça.
class AbsenceReasonStats extends Equatable {
  final AbsenceReason? reason;
  final int absenceDays;

  const AbsenceReasonStats({required this.reason, required this.absenceDays});

  @override
  List<Object?> get props => [reason, absenceDays];
}
