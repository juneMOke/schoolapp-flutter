import 'dart:convert';

import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/course_programme/data/local/chapitre_fiche_codec.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_note.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_ressource.dart';

/// Les trois tables du programme, nommées une fois.
class ProgrammeTables {
  ProgrammeTables._();

  static const String chapitre = 'chapitre';
  static const String note = 'chapitre_note';
  static const String ressource = 'chapitre_ressource';
}

ProgrammeSyncState programmeSyncStateOf(Object? dbValue) =>
    switch (SyncState.fromDbValue(dbValue as String?)) {
      SyncState.synced => ProgrammeSyncState.synced,
      SyncState.syncError => ProgrammeSyncState.rejected,
      _ => ProgrammeSyncState.pending,
    };

/// L'instant [ms] en ISO-8601 UTC, la forme rangée en base et sur le fil.
String programmeInstant(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

DateTime? _instant(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;

/// Lecture et écriture d'une ligne `chapitre`. Les instants sont rangés en
/// ISO-8601 UTC, comme sur le fil.
class ChapitreRowMapper {
  ChapitreRowMapper._();

  static Chapitre toEntity(Map<String, Object?> row) => Chapitre(
    id: row['id'] as String,
    coursId: row['cours_id'] as String,
    ordre: (row['ordre'] as int?) ?? 0,
    titre: row['titre'] as String,
    resume: row['resume'] as String?,
    statut: ChapitreStatut.fromWire(row['statut'] as String?),
    seances: (row['seances'] as int?) ?? Chapitre.defaultSeances,
    sousPeriodeId: row['sous_periode_id'] as String?,
    objectifs: ChapitreFicheCodec.objectifsFromJson(
      ChapitreFicheCodec.decodeColumn(row['objectifs_json']),
    ),
    strategies: ChapitreFicheCodec.strategiesFromJson(
      ChapitreFicheCodec.decodeColumn(row['strategies_json']),
    ),
    blocs: ChapitreFicheCodec.blocsFromJson(
      ChapitreFicheCodec.decodeColumn(row['blocs_json']),
    ),
    clientUpdatedAt: _instant(row['client_updated_at']),
    syncState: programmeSyncStateOf(row['sync_status']),
    rejectionCode: row['sync_error_code'] as String?,
    awaitingDownload:
        row['server_known'] == 1 && row['server_updated_at'] == null,
  );

  /// Les colonnes de la **fiche** — ce qu'un enregistrement local réécrit.
  /// Ni `ordre` (le geste d'ordre), ni l'état serveur (`server_*`).
  static Map<String, Object?> ficheColumns(Chapitre chapitre) => {
    'titre': chapitre.titre,
    'resume': chapitre.resume,
    'statut': chapitre.statut.wireValue,
    'seances': chapitre.seances,
    'sous_periode_id': chapitre.sousPeriodeId,
    'objectifs_json': jsonEncode(
      ChapitreFicheCodec.objectifsToJson(chapitre.objectifs),
    ),
    'strategies_json': jsonEncode(chapitre.strategies),
    'blocs_json': jsonEncode(ChapitreFicheCodec.blocsToJson(chapitre.blocs)),
    'client_updated_at': chapitre.clientUpdatedAt?.toUtc().toIso8601String(),
  };
}

/// Lecture d'une ligne `chapitre_note`.
class ChapitreNoteRowMapper {
  ChapitreNoteRowMapper._();

  static ChapitreNote toEntity(Map<String, Object?> row) => ChapitreNote(
    id: row['id'] as String,
    chapitreId: row['chapitre_id'] as String,
    texte: row['texte'] as String,
    ecriteLe: _instant(row['ecrite_le']) ?? DateTime.utc(1970),
    auteur: row['auteur'] as String?,
    syncState: programmeSyncStateOf(row['sync_status']),
  );
}

/// Lecture d'une ligne `chapitre_ressource`.
class ChapitreRessourceRowMapper {
  ChapitreRessourceRowMapper._();

  static ChapitreRessource toEntity(Map<String, Object?> row) =>
      ChapitreRessource(
        id: row['id'] as String,
        chapitreId: row['chapitre_id'] as String,
        type: RessourceType.fromWire(row['type'] as String?),
        nom: row['nom'] as String,
        url: row['url'] as String?,
        reference: row['reference'] as String?,
        taille: row['taille'] as int?,
        sha256: row['sha256'] as String?,
        mimeType: row['mime_type'] as String?,
        fileName: row['file_name'] as String?,
        syncState: programmeSyncStateOf(row['sync_status']),
        rejectionCode: row['sync_error_code'] as String?,
      );
}
