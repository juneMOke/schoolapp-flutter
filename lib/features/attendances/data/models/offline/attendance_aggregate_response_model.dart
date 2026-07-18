import 'package:equatable/equatable.dart';

/// Réponse du serveur au push d'un agrégat d'appel (`POST /sync/attendance`).
///
/// On ne consomme que ce dont la tablette a besoin pour se réaligner (AG-3) :
/// l'id canonique + `serverUpdatedAt` (visibilité) + `expectedCount` (snapshot
/// roster serveur, informatif) + `lwwOutcome`. L'état canonique des absences
/// n'est pas réappliqué : en contexte **mono-tablette** le `SUPERSEDED` ne se
/// produit pas (le local est déjà l'état gagnant) — filet du régime C.
class AttendanceAggregateResponseModel extends Equatable {
  final String sessionId;
  final String? serverUpdatedAt;
  final int? expectedCount;

  /// `APPLIED` (écriture retenue) | `SUPERSEDED` (un état plus récent existait).
  final String lwwOutcome;

  const AttendanceAggregateResponseModel({
    required this.sessionId,
    this.serverUpdatedAt,
    this.expectedCount,
    required this.lwwOutcome,
  });

  factory AttendanceAggregateResponseModel.fromJson(Map<String, dynamic> json) {
    final session = (json['session'] as Map<String, dynamic>?) ?? const {};
    return AttendanceAggregateResponseModel(
      sessionId: session['id'] as String? ?? '',
      serverUpdatedAt: session['serverUpdatedAt'] as String?,
      expectedCount: (session['expectedCount'] as num?)?.toInt(),
      lwwOutcome: json['lwwOutcome'] as String? ?? 'APPLIED',
    );
  }

  bool get isSuperseded => lwwOutcome == 'SUPERSEDED';

  @override
  List<Object?> get props => [
    sessionId,
    serverUpdatedAt,
    expectedCount,
    lwwOutcome,
  ];
}
