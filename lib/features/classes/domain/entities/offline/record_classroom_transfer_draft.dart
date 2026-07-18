import 'package:equatable/equatable.dart';

/// Intention métier d'un transfert d'élève (CF4, offline). Entrée du repository
/// offline : le `from`/`level` sont résolus depuis le miroir local avant
/// l'écriture ; l'`id` de l'événement et l'heure métier sont posés côté data.
///
/// **Même niveau uniquement** : `fromClassroomId` et `toClassroomId` partagent le
/// `schoolLevelId` (garanti par le sélecteur, double-gardé serveur → 422). Le
/// `reason` est libre et optionnel.
class RecordClassroomTransferDraft extends Equatable {
  final String studentId;
  final String fromClassroomId;
  final String toClassroomId;
  final String schoolLevelId;
  final String academicYearId;
  final String? transferredBy;
  final String? reason;

  const RecordClassroomTransferDraft({
    required this.studentId,
    required this.fromClassroomId,
    required this.toClassroomId,
    required this.schoolLevelId,
    required this.academicYearId,
    this.transferredBy,
    this.reason,
  });

  @override
  List<Object?> get props => [
    studentId,
    fromClassroomId,
    toClassroomId,
    schoolLevelId,
    academicYearId,
    transferredBy,
    reason,
  ];
}
