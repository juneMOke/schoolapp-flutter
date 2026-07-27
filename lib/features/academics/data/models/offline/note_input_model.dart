import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_evaluation_row.dart';

/// Une note d'un lot poussé au `/sync` (régime C, LWW) — `NoteLineInput`. Le
/// serveur upsert sur la clé naturelle `(evaluationId, studentId)` si
/// `updatedAt` entrant est plus récent. `pointsObtenus` nul = absent (le
/// `statut` porte alors l'absence). `evaluationId` voyage **par ligne** (le
/// contrat `NoteBatchSyncRequest` ne le porte pas au niveau du lot).
class NoteInputModel extends Equatable {
  final String evaluationId;
  final String studentId;
  final String statut;
  final double? pointsObtenus;

  /// ISO-8601 (arbitre LWW).
  final String updatedAt;

  const NoteInputModel({
    required this.evaluationId,
    required this.studentId,
    required this.statut,
    this.pointsObtenus,
    required this.updatedAt,
  });

  /// `updatedAt` local (epoch ms) → ISO.
  factory NoteInputModel.fromRow(NoteEvaluationRow row) => NoteInputModel(
    evaluationId: row.evaluationId,
    studentId: row.studentId,
    statut: row.statut,
    pointsObtenus: row.pointsObtenus,
    updatedAt: EpochIsoHelper.toIso(row.updatedAt),
  );

  factory NoteInputModel.fromJson(Map<String, dynamic> json) => NoteInputModel(
    evaluationId: json['evaluationId'] as String,
    studentId: json['studentId'] as String,
    statut: json['statut'] as String,
    pointsObtenus: (json['pointsObtenus'] as num?)?.toDouble(),
    updatedAt: json['updatedAt'] as String,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'evaluationId': evaluationId,
    'studentId': studentId,
    'statut': statut,
    // Toujours présent (peut être null) : distingue « absent » d'« omis ».
    'pointsObtenus': pointsObtenus,
    'updatedAt': updatedAt,
  };

  /// `updatedAt` (ISO) reconstruit en epoch ms — la valeur POUSSÉE, base de la
  /// garde LWW du réalignement post-ACK.
  int? get updatedAtMs => EpochIsoHelper.tryToEpochMs(updatedAt);

  @override
  List<Object?> get props => [
    evaluationId,
    studentId,
    statut,
    pointsObtenus,
    updatedAt,
  ];
}
