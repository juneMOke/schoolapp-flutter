import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';

/// L'identité d'un agent telle que chaque ligne des statistiques de présence
/// la porte : de quoi le nommer, le ranger et savoir s'il est payé à l'heure,
/// sans relire le fichier local.
///
/// Les valeurs fermées se lisent avec tolérance : une catégorie ou un contrat
/// inconnu de ce poste se lit `null` plutôt que de rendre la liste illisible.
class HrAttendanceAgent extends Equatable {
  final String staffMemberId;
  final String staffNumber;
  final String lastName;
  final String? middleName;
  final String? firstName;
  final String? jobTitle;
  final StaffCategory? category;
  final StaffContractKind? contractKind;
  final StaffPayMode? payMode;

  const HrAttendanceAgent({
    required this.staffMemberId,
    required this.staffNumber,
    required this.lastName,
    this.middleName,
    this.firstName,
    this.jobTitle,
    this.category,
    this.contractKind,
    this.payMode,
  });

  /// Payé à l'heure : ses heures comptent, ses jours sans cours ne sont
  /// jamais « non pointés » (D2).
  bool get isHourly => payMode == StaffPayMode.hourly;

  @override
  List<Object?> get props => [
    staffMemberId,
    staffNumber,
    lastName,
    middleName,
    firstName,
    jobTitle,
    category,
    contractKind,
    payMode,
  ];
}
