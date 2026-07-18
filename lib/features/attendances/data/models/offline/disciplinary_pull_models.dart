// DTOs de pull delta de la Discipline (contrat openapi_discipline_sync 1.1.0,
// `GET /sync/disciplinary-cases`). Cas paginés keyset, commentaires imbriqués.
// Réponses serveur (fromJson) → converties en lignes locales à l'application.

import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/disciplinary_comment_row.dart';
import 'package:school_app_flutter/features/attendances/data/models/offline/offline_disciplinary_case_row.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

/// Mappe une liste serveur en **tolérant les lignes malformées** : une ligne
/// dont le `fromJson` lève est ignorée au lieu de figer le curseur (anti
/// poison-page). La ligne écartée réapparaîtra au prochain delta une fois
/// corrigée côté serveur.
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

/// Agrégat local prêt à appliquer : le cas + ses commentaires (déjà résolus en
/// lignes locales SYNCED). L'id du cas est l'uuid honoré (idempotence).
class PulledDisciplinaryCase {
  final OfflineDisciplinaryCaseRow caseRow;
  final List<DisciplinaryCommentRow> comments;

  const PulledDisciplinaryCase({required this.caseRow, required this.comments});
}

/// Un commentaire imbriqué dans un cas pullé (append-only).
class DisciplinaryCommentDeltaDto {
  final String id;
  final String content;
  final String? authorName;
  final String createdAt;

  const DisciplinaryCommentDeltaDto({
    required this.id,
    required this.content,
    this.authorName,
    required this.createdAt,
  });

  factory DisciplinaryCommentDeltaDto.fromJson(Map<String, dynamic> j) =>
      DisciplinaryCommentDeltaDto(
        id: j['id'] as String,
        content: j['content'] as String,
        authorName: j['authorName'] as String?,
        createdAt: j['createdAt'] as String,
      );

  DisciplinaryCommentRow toLocalRow({
    required String caseId,
    required int syncedAt,
  }) => DisciplinaryCommentRow(
    id: id,
    disciplinaryCaseId: caseId,
    content: content,
    authorName: authorName,
    createdAt: _isoToMs(createdAt) ?? syncedAt,
    syncStatus: SyncState.synced.dbValue,
    syncedAt: syncedAt,
  );
}

/// Un cas pullé (racine d'agrégat) avec ses commentaires imbriqués.
///
/// ⚠ Le delta **ne porte pas** `studentGender` (résolu à la création ; le back
/// ne le renvoie pas en lecture) → défaut `OTHER` en local. `content` peut être
/// nul (visibilité par rôle serveur, différée) → défaut `''` (colonne NOT NULL).
class DisciplinaryCaseDeltaDto {
  final String id;
  final String studentId;
  final String? studentFirstName;
  final String? studentLastName;
  final String? studentMiddleName;
  final String academicYearId;
  final String category;
  final String severity;
  final String title;
  final String? content;
  final String disciplinaryCaseDate;
  final String status;
  final String? sanction;
  final String? clientUpdatedAt;
  final String serverUpdatedAt;
  final List<DisciplinaryCommentDeltaDto> comments;

  const DisciplinaryCaseDeltaDto({
    required this.id,
    required this.studentId,
    this.studentFirstName,
    this.studentLastName,
    this.studentMiddleName,
    required this.academicYearId,
    required this.category,
    required this.severity,
    required this.title,
    this.content,
    required this.disciplinaryCaseDate,
    required this.status,
    this.sanction,
    this.clientUpdatedAt,
    required this.serverUpdatedAt,
    this.comments = const [],
  });

  factory DisciplinaryCaseDeltaDto.fromJson(Map<String, dynamic> j) =>
      DisciplinaryCaseDeltaDto(
        id: j['id'] as String,
        studentId: j['studentId'] as String,
        studentFirstName: j['studentFirstName'] as String?,
        studentLastName: j['studentLastName'] as String?,
        studentMiddleName: j['studentMiddleName'] as String?,
        academicYearId: j['academicYearId'] as String,
        category: (j['category'] as String?) ?? 'DISRUPTIVE_BEHAVIOR',
        severity: (j['severity'] as String?) ?? 'MINOR',
        title: j['title'] as String,
        content: j['content'] as String?,
        disciplinaryCaseDate: j['disciplinaryCaseDate'] as String,
        status: (j['status'] as String?) ?? 'OPEN',
        sanction: j['sanction'] as String?,
        clientUpdatedAt: j['clientUpdatedAt'] as String?,
        serverUpdatedAt: j['serverUpdatedAt'] as String,
        comments: _lenientList(
          j['comments'],
          DisciplinaryCommentDeltaDto.fromJson,
        ),
      );

  PulledDisciplinaryCase toPulled(int syncedAt) {
    final serverMs = _isoToMs(serverUpdatedAt);
    return PulledDisciplinaryCase(
      caseRow: OfflineDisciplinaryCaseRow(
        id: id,
        studentId: studentId,
        studentFirstName: studentFirstName ?? '',
        studentLastName: studentLastName ?? '',
        studentMiddleName: studentMiddleName,
        studentGender: 'OTHER',
        academicYearId: academicYearId,
        disciplinaryCaseDate: disciplinaryCaseDate,
        title: title,
        content: content ?? '',
        category: category,
        severity: severity,
        status: status,
        sanction: sanction,
        updatedAt: _isoToMs(clientUpdatedAt) ?? serverMs ?? syncedAt,
        serverUpdatedAt: serverMs,
        syncStatus: SyncState.synced.dbValue,
        syncedAt: syncedAt,
      ),
      comments: comments
          .map((c) => c.toLocalRow(caseId: id, syncedAt: syncedAt))
          .toList(growable: false),
    );
  }
}

/// Page keyset de cas (commentaires imbriqués).
class DisciplinaryCasePageDto
    implements KeysetPageDto<DisciplinaryCaseDeltaDto> {
  @override
  final List<DisciplinaryCaseDeltaDto> items;
  @override
  final KeysetPageEnvelope page;

  const DisciplinaryCasePageDto({required this.items, required this.page});

  factory DisciplinaryCasePageDto.fromJson(Map<String, dynamic> j) =>
      DisciplinaryCasePageDto(
        items: _lenientList(j['items'], DisciplinaryCaseDeltaDto.fromJson),
        page: KeysetPageEnvelope.fromJson(j),
      );
}
