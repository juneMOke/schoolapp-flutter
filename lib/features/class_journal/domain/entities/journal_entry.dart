import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_seance_key.dart';

/// Ce qui a été fait à une séance datée : une entrée par (cours, date,
/// créneau), à l'identifiant déterministe (`JournalIds`).
///
/// Une entrée ne se supprime jamais : vider une séance enregistre ses sept
/// champs vides, sans chapitre.
class JournalEntry extends Equatable {
  final String id;
  final String coursId;

  /// Le jour civil de la séance (minuit, heure locale).
  final DateTime date;
  final String timeSlotId;

  /// `null` : séance hors programme.
  final String? chapitreId;
  final JournalFields fields;
  final DateTime? clientUpdatedAt;
  final RecordSyncState syncState;

  /// Le code du dernier refus du serveur, quand [syncState] est `failed`.
  final String? rejectionCode;

  const JournalEntry({
    required this.id,
    required this.coursId,
    required this.date,
    required this.timeSlotId,
    this.chapitreId,
    this.fields = JournalFields.empty,
    this.clientUpdatedAt,
    this.syncState = RecordSyncState.synced,
    this.rejectionCode,
  });

  JournalSeanceKey get key =>
      JournalSeanceKey(coursId: coursId, date: date, timeSlotId: timeSlotId);

  bool get isFilled => fields.isFilled;

  /// Vidée : aucun champ ni chapitre — comme si rien n'avait été saisi.
  bool get isBlank => fields.isBlank && chapitreId == null;

  bool get isRejected => syncState == RecordSyncState.failed;

  @override
  List<Object?> get props => [
    id,
    coursId,
    date,
    timeSlotId,
    chapitreId,
    fields,
    clientUpdatedAt,
    syncState,
    rejectionCode,
  ];
}
