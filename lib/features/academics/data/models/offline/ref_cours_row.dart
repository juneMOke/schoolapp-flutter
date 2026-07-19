import 'package:equatable/equatable.dart';

/// Ligne sqflite `ref_cours` — le cours au sens back : une **ligne de barème
/// enseignée dans UNE classe** (clé serveur `(classroom_id, ligne_bareme_id)`).
/// **Référence pure, lecture seule** (peuplée par le pull, par classe).
/// `classroomId` donne le roster (via `ref_classroom_members`, module Classe) ;
/// `ligneBaremeId` est le pont vers le poste de bulletin (calcul serveur).
class RefCoursRow extends Equatable {
  final String id;
  final String classroomId;
  final String ligneBaremeId;
  final String? teacherId;
  final int? serverUpdatedAt;
  final int syncedAt;

  const RefCoursRow({
    required this.id,
    required this.classroomId,
    required this.ligneBaremeId,
    this.teacherId,
    this.serverUpdatedAt,
    required this.syncedAt,
  });

  static int? _asIntOrNull(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  factory RefCoursRow.fromMap(Map<String, Object?> map) => RefCoursRow(
    id: map['id'] as String,
    classroomId: map['classroom_id'] as String,
    ligneBaremeId: map['ligne_bareme_id'] as String,
    teacherId: map['teacher_id'] as String?,
    serverUpdatedAt: _asIntOrNull(map['server_updated_at']),
    syncedAt: _asIntOrNull(map['synced_at']) ?? 0,
  );

  Map<String, Object?> toMap() => <String, Object?>{
    'id': id,
    'classroom_id': classroomId,
    'ligne_bareme_id': ligneBaremeId,
    'teacher_id': teacherId,
    'server_updated_at': serverUpdatedAt,
    'synced_at': syncedAt,
  };

  @override
  List<Object?> get props => [
    id,
    classroomId,
    ligneBaremeId,
    teacherId,
    serverUpdatedAt,
    syncedAt,
  ];
}
