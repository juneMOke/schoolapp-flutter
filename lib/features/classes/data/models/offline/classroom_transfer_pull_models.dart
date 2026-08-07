// DTOs de pull delta des transferts (contrat openapi_classroom_sync 1.1.0,
// `GET /sync/classroom-transfers`). Transferts paginés keyset. Réponses serveur
// (fromJson) → converties en lignes locales SYNCED à l'application.

import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/classes/data/models/offline/classroom_transfer_row.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

/// Mappe une liste serveur en **tolérant les lignes malformées** : une ligne
/// dont le `fromJson` lève est ignorée au lieu de figer le curseur (anti
/// poison-page). Elle réapparaîtra au prochain delta une fois corrigée serveur.
List<T> _lenientList<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  final out = <T>[];
  for (final e in (raw as List<dynamic>? ?? const [])) {
    try {
      out.add(parse(e as Map<String, dynamic>));
    } catch (_) {
      // Ligne écartée : le curseur avance, la ressource ne fige pas.
    }
  }
  return out;
}

int? _isoToMs(String? iso) =>
    iso == null ? null : DateTime.tryParse(iso)?.millisecondsSinceEpoch;

/// Un transfert pullé (événement visible serveur : ce poste ou en ligne). Le
/// contrat ne porte pas `schoolLevelId` (non nécessaire au dénominateur ni à la
/// composition) — le DAO le résout depuis `ref_classrooms(to)` à l'application.
class ClassroomTransferDeltaDto {
  final String id;
  final String studentId;
  final String fromClassroomId;
  final String toClassroomId;
  final String academicYearId;
  final String transferredAt;
  final String? transferredBy;
  final String? reason;
  final String serverUpdatedAt;

  const ClassroomTransferDeltaDto({
    required this.id,
    required this.studentId,
    required this.fromClassroomId,
    required this.toClassroomId,
    required this.academicYearId,
    required this.transferredAt,
    required this.serverUpdatedAt,
    this.transferredBy,
    this.reason,
  });

  factory ClassroomTransferDeltaDto.fromJson(Map<String, dynamic> j) =>
      ClassroomTransferDeltaDto(
        id: j['id'] as String,
        studentId: j['studentId'] as String,
        fromClassroomId: j['fromClassroomId'] as String,
        toClassroomId: j['toClassroomId'] as String,
        academicYearId: j['academicYearId'] as String,
        transferredAt: j['transferredAt'] as String,
        transferredBy: j['transferredBy'] as String?,
        reason: j['reason'] as String?,
        serverUpdatedAt: j['serverUpdatedAt'] as String,
      );

  /// Ligne locale SYNCED. [schoolLevelId] résolu par le DAO (`''` si la classe
  /// destination n'est pas encore en base — champ non lu pour un SYNCED).
  ClassroomTransferRow toRow({
    required int syncedAt,
    required String schoolLevelId,
  }) => ClassroomTransferRow(
    id: id,
    studentId: studentId,
    fromClassroomId: fromClassroomId,
    toClassroomId: toClassroomId,
    schoolLevelId: schoolLevelId,
    academicYearId: academicYearId,
    transferredAt: _isoToMs(transferredAt) ?? syncedAt,
    transferredBy: transferredBy,
    reason: reason,
    syncStatus: SyncState.synced.dbValue,
    serverUpdatedAt: _isoToMs(serverUpdatedAt),
    syncedAt: syncedAt,
  );
}

/// Page keyset de transferts.
class ClassroomTransferPageDto
    implements KeysetPageDto<ClassroomTransferDeltaDto> {
  @override
  final List<ClassroomTransferDeltaDto> items;
  @override
  final KeysetPageEnvelope page;

  const ClassroomTransferPageDto({required this.items, required this.page});

  factory ClassroomTransferPageDto.fromJson(Map<String, dynamic> j) =>
      ClassroomTransferPageDto(
        items: _lenientList(j['items'], ClassroomTransferDeltaDto.fromJson),
        page: KeysetPageEnvelope.fromJson(j),
      );
}
