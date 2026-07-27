// DTOs de pull delta métier (contrat PLAN_notes_cours_offline) :
// `GET /sync/academics/evaluations?coursId=` et `.../notes?coursId=`. Pages
// keyset par cours, curseurs INDÉPENDANTS. Réponses serveur → lignes locales
// SYNCED à l'application (le DAO skippe les lignes PENDING_SYNC).

import 'package:school_app_flutter/features/academics/data/models/offline/evaluation_row.dart';
import 'package:school_app_flutter/features/academics/data/models/offline/note_evaluation_row.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/sync/keyset_page.dart';

List<T> _lenientList<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
  final out = <T>[];
  for (final e in (raw as List<dynamic>? ?? const [])) {
    try {
      out.add(parse(e as Map<String, dynamic>));
    } catch (_) {
      // Ligne écartée (anti poison-page) : le curseur ne fige pas.
    }
  }
  return out;
}

int? _isoToMs(String? iso) {
  if (iso == null) return null;
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return null;
  final utc = parsed.isUtc
      ? parsed
      : DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
  return utc.millisecondsSinceEpoch;
}

/// Date-only `yyyy-MM-dd` → epoch ms (UTC minuit). Null si illisible.
int? _dateOnlyToMs(String? value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return null;
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
  ).millisecondsSinceEpoch;
}

// ── Évaluations (régime A) ────────────────────────────────────────────────────

class EvaluationDeltaDto {
  final String id;
  final String coursId;
  final String type;
  final String date;
  final double maxPoints;
  final int poids;
  final String? sousPeriodeId;
  final String? periodeScolaireId;
  final List<String> chapitreIds;
  final String serverUpdatedAt;

  const EvaluationDeltaDto({
    required this.id,
    required this.coursId,
    required this.type,
    required this.date,
    required this.maxPoints,
    required this.poids,
    this.sousPeriodeId,
    this.periodeScolaireId,
    this.chapitreIds = const [],
    required this.serverUpdatedAt,
  });

  factory EvaluationDeltaDto.fromJson(Map<String, dynamic> j) =>
      EvaluationDeltaDto(
        id: j['id'] as String,
        coursId: j['coursId'] as String,
        type: (j['type'] as String?) ?? 'UNKNOWN',
        date: j['date'] as String,
        maxPoints: (j['maxPoints'] as num).toDouble(),
        poids: (j['poids'] as num?)?.toInt() ?? 1,
        sousPeriodeId: j['sousPeriodeId'] as String?,
        periodeScolaireId: j['periodeScolaireId'] as String?,
        chapitreIds:
            (j['chapitreIds'] as List<dynamic>?)?.whereType<String>().toList(
              growable: false,
            ) ??
            const [],
        serverUpdatedAt: j['serverUpdatedAt'] as String,
      );

  EvaluationRow toLocalRow(int syncedAt) {
    final serverMs = _isoToMs(serverUpdatedAt);
    return EvaluationRow(
      id: id,
      coursId: coursId,
      type: type,
      evalDate: _dateOnlyToMs(date) ?? serverMs ?? syncedAt,
      maxPoints: maxPoints,
      poids: poids,
      sousPeriodeId: sousPeriodeId,
      periodeScolaireId: periodeScolaireId,
      updatedAt: serverMs ?? syncedAt,
      serverUpdatedAt: serverMs,
      syncStatus: 'SYNCED',
      syncedAt: syncedAt,
      chapitreIdsJson: EvaluationRow.encodeChapitreIds(chapitreIds),
    );
  }
}

class EvaluationPageDto implements KeysetPageDto<EvaluationDeltaDto> {
  @override
  final List<EvaluationDeltaDto> items;
  @override
  final KeysetPageEnvelope page;

  const EvaluationPageDto({required this.items, required this.page});

  factory EvaluationPageDto.fromJson(Map<String, dynamic> j) =>
      EvaluationPageDto(
        items: _lenientList(j['items'], EvaluationDeltaDto.fromJson),
        page: KeysetPageEnvelope.fromJson(j),
      );
}

// ── Notes (régime C) ──────────────────────────────────────────────────────────

class NoteDeltaDto {
  final String id;
  final String evaluationId;
  final String studentId;
  final double? pointsObtenus;
  final String statut;
  final String? clientUpdatedAt;
  final String serverUpdatedAt;

  const NoteDeltaDto({
    required this.id,
    required this.evaluationId,
    required this.studentId,
    this.pointsObtenus,
    required this.statut,
    this.clientUpdatedAt,
    required this.serverUpdatedAt,
  });

  factory NoteDeltaDto.fromJson(Map<String, dynamic> j) => NoteDeltaDto(
    id: j['id'] as String,
    evaluationId: j['evaluationId'] as String,
    studentId: j['studentId'] as String,
    pointsObtenus: (j['pointsObtenus'] as num?)?.toDouble(),
    statut: (j['statut'] as String?) ?? 'EN_ATTENTE',
    clientUpdatedAt: j['clientUpdatedAt'] as String?,
    serverUpdatedAt: j['serverUpdatedAt'] as String,
  );

  NoteEvaluationRow toLocalRow(int syncedAt) {
    final serverMs = _isoToMs(serverUpdatedAt);
    return NoteEvaluationRow(
      id: id,
      evaluationId: evaluationId,
      studentId: studentId,
      pointsObtenus: pointsObtenus,
      statut: statut,
      // `updated_at` = horloge CLIENT (arbitre LWW) : on garde celle du serveur
      // (dernière écriture gagnante déjà tranchée serveur), fallback visibilité.
      updatedAt: _isoToMs(clientUpdatedAt) ?? serverMs ?? syncedAt,
      serverUpdatedAt: serverMs,
      syncStatus: 'SYNCED',
      syncedAt: syncedAt,
    );
  }
}

class NotePageDto implements KeysetPageDto<NoteDeltaDto> {
  @override
  final List<NoteDeltaDto> items;
  @override
  final KeysetPageEnvelope page;

  const NotePageDto({required this.items, required this.page});

  factory NotePageDto.fromJson(Map<String, dynamic> j) => NotePageDto(
    items: _lenientList(j['items'], NoteDeltaDto.fromJson),
    page: KeysetPageEnvelope.fromJson(j),
  );
}
