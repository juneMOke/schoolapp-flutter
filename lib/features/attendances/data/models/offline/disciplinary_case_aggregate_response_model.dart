import 'package:equatable/equatable.dart';

/// Réponse du serveur au push de l'agrégat disciplinaire
/// (`POST /sync/disciplinary-cases`).
///
/// On ne consomme que ce dont la tablette a besoin pour se réaligner : l'id
/// canonique + `status`/`sanction` gagnants + `serverUpdatedAt` (visibilité) +
/// `lwwOutcome`. En contexte **mono-préfet**, `SUPERSEDED` ne se produit pas
/// (le local est déjà l'état gagnant) — filet du régime C, traité comme un succès.
class DisciplinaryCaseAggregateResponseModel extends Equatable {
  final String caseId;
  final String? status;
  final String? sanction;

  /// ISO-8601 (temps de visibilité serveur).
  final String? serverUpdatedAt;

  /// `APPLIED` (traitement retenu) | `SUPERSEDED` (un état plus récent existait).
  final String lwwOutcome;

  const DisciplinaryCaseAggregateResponseModel({
    required this.caseId,
    this.status,
    this.sanction,
    this.serverUpdatedAt,
    required this.lwwOutcome,
  });

  factory DisciplinaryCaseAggregateResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final caseJson = (json['case'] as Map<String, dynamic>?) ?? const {};
    return DisciplinaryCaseAggregateResponseModel(
      caseId: caseJson['id'] as String? ?? '',
      status: caseJson['status'] as String?,
      sanction: caseJson['sanction'] as String?,
      serverUpdatedAt: caseJson['serverUpdatedAt'] as String?,
      lwwOutcome: json['lwwOutcome'] as String? ?? 'APPLIED',
    );
  }

  bool get isSuperseded => lwwOutcome == 'SUPERSEDED';

  @override
  List<Object?> get props => [
    caseId,
    status,
    sanction,
    serverUpdatedAt,
    lwwOutcome,
  ];
}
