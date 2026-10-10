import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/core/offline/lww_outcome.dart';
import 'package:school_app_flutter/features/class_journal/data/sync/journal_entry_dto.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_entry.dart';

/// L'entrée telle qu'elle part (`POST /sync/academics/journal`, sous `entry`).
/// Le round-trip `toJson` → `tryParse` EST le chemin du push : l'outbox range
/// le texte, le handler le relit.
class JournalEntryPayload {
  final String entryId;
  final String coursId;
  final Map<String, Object?> entry;

  const JournalEntryPayload._(this.entryId, this.coursId, this.entry);

  factory JournalEntryPayload.of(JournalEntry e) =>
      JournalEntryPayload._(e.id, e.coursId, {
        'id': e.id,
        'coursId': e.coursId,
        'date': DateOnlyJsonHelper.toJson(e.date),
        'timeSlotId': e.timeSlotId,
        'chapitreId': e.chapitreId,
        'cb': e.fields.cb,
        'objectif': e.fields.objectif,
        'contenu': e.fields.contenu,
        'strategie': e.fields.strategie,
        'ressources': e.fields.ressources,
        'evaluation': e.fields.evaluation,
        'observation': e.fields.observation,
        'clientUpdatedAt': e.clientUpdatedAt?.toUtc().toIso8601String(),
      });

  String? get chapitreId => _string(entry['chapitreId']);

  /// L'horloge de l'entrée envoyée ; c'est elle que l'accusé compare à la
  /// ligne locale.
  String? get clientUpdatedAt => _string(entry['clientUpdatedAt']);

  /// La même entrée, sans chapitre : celui qu'elle citait a quitté la
  /// tablette, le serveur le détacherait de toute façon.
  JournalEntryPayload detached() =>
      JournalEntryPayload._(entryId, coursId, {...entry, 'chapitreId': null});

  Map<String, Object?> toJson() => {
    'entryId': entryId,
    'coursId': coursId,
    'entry': entry,
  };

  static JournalEntryPayload? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final entryId = _string(raw['entryId']);
    final coursId = _string(raw['coursId']);
    final entry = raw['entry'];
    if (entryId == null || coursId == null || entry is! Map) return null;
    return JournalEntryPayload._(
      entryId,
      coursId,
      Map<String, Object?>.from(entry),
    );
  }

  static String? _string(Object? value) => value is String ? value : null;
}

/// L'accusé d'un envoi : l'entrée que le serveur a retenue, et s'il a écrit
/// la nôtre ou en détenait une plus récente.
class JournalEntryAck {
  final JournalEntryDto entry;
  final bool superseded;

  const JournalEntryAck({required this.entry, required this.superseded});

  /// Lève [FormatException] sur un accusé sans entrée lisible : le handler le
  /// traite en échec local, donc en tentative — l'envoi est rejouable.
  factory JournalEntryAck.fromJson(Map<String, dynamic> json) {
    final entry = JournalEntryDto.tryParse(json['entry']);
    if (entry == null) throw const FormatException('Accusé illisible');
    return JournalEntryAck(
      entry: entry,
      superseded:
          LwwOutcome.fromWire(json['lwwOutcome']) == LwwOutcome.superseded,
    );
  }
}
