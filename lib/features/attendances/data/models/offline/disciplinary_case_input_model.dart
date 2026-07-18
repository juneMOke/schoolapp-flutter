import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/epoch_iso_helper.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_disciplinary_case_row.dart';

/// Volet `case` de l'agrégat poussé au `/sync` (contrat 1.1.0,
/// `DisciplinaryCaseInput`). Le FAIT (immuable côté serveur après création) +
/// le TRAITEMENT (`status`/`sanction`, LWW `clientUpdatedAt`).
///
/// ⚠ Les **noms de l'élève ne sont PAS envoyés** (résolus serveur, ERRATA). Le
/// `clientUpdatedAt` est l'arbitre LWW : l'`updated_at` local (epoch ms) sérialisé
/// en ISO-8601.
class DisciplinaryCaseInputModel extends Equatable {
  final String id;
  final String studentId;
  final String academicYearId;
  final String category;
  final String severity;
  final String title;
  final String? content;

  /// 'yyyy-MM-dd'.
  final String disciplinaryCaseDate;
  final String status;
  final String? sanction;

  /// ISO-8601 (arbitre LWW).
  final String clientUpdatedAt;

  const DisciplinaryCaseInputModel({
    required this.id,
    required this.studentId,
    required this.academicYearId,
    required this.category,
    required this.severity,
    required this.title,
    this.content,
    required this.disciplinaryCaseDate,
    required this.status,
    this.sanction,
    required this.clientUpdatedAt,
  });

  /// Construit le volet `case` depuis la ligne locale. `clientUpdatedAt` dérivé
  /// de `row.updatedAt` (epoch ms → ISO).
  factory DisciplinaryCaseInputModel.fromRow(OfflineDisciplinaryCaseRow row) =>
      DisciplinaryCaseInputModel(
        id: row.id,
        studentId: row.studentId,
        academicYearId: row.academicYearId,
        category: row.category,
        severity: row.severity,
        title: row.title,
        content: row.content,
        disciplinaryCaseDate: row.disciplinaryCaseDate,
        status: row.status,
        sanction: row.sanction,
        clientUpdatedAt: EpochIsoHelper.toIso(row.updatedAt),
      );

  factory DisciplinaryCaseInputModel.fromJson(Map<String, dynamic> json) =>
      DisciplinaryCaseInputModel(
        id: json['id'] as String,
        studentId: json['studentId'] as String,
        academicYearId: json['academicYearId'] as String,
        category: (json['category'] as String?) ?? 'DISRUPTIVE_BEHAVIOR',
        severity: (json['severity'] as String?) ?? 'MINOR',
        title: json['title'] as String,
        content: json['content'] as String?,
        disciplinaryCaseDate: json['disciplinaryCaseDate'] as String,
        status: (json['status'] as String?) ?? 'OPEN',
        sanction: json['sanction'] as String?,
        clientUpdatedAt: json['clientUpdatedAt'] as String,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'studentId': studentId,
    'academicYearId': academicYearId,
    'category': category,
    'severity': severity,
    'title': title,
    'content': content,
    'disciplinaryCaseDate': disciplinaryCaseDate,
    'status': status,
    // Toujours présent (peut être null) : renvoie la sanction courante (DG-4).
    'sanction': sanction,
    'clientUpdatedAt': clientUpdatedAt,
  };

  /// L'`updated_at` local (epoch ms) reconstruit depuis `clientUpdatedAt`, pour
  /// la garde de `markAggregateSynced` (ne marque SYNCED que si non re-muté).
  int? get clientUpdatedAtMs => EpochIsoHelper.tryToEpochMs(clientUpdatedAt);

  // `content` SENSIBLE (mineur) : jamais rendu par toString() (fuite debug).
  @override
  bool? get stringify => false;

  @override
  List<Object?> get props => [
    id,
    studentId,
    academicYearId,
    category,
    severity,
    title,
    content,
    disciplinaryCaseDate,
    status,
    sanction,
    clientUpdatedAt,
  ];
}
