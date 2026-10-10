import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_seance_key.dart';
import 'package:uuid/uuid.dart';

/// L'identifiant d'une entrée du journal : **le même sur toutes les tablettes**
/// et au serveur — RFC 4122 v5, espace de noms = l'uuid du cours, nom =
/// `journal:AAAA-MM-JJ:<timeSlotId>`. Deux postes qui remplissent la même
/// séance écrivent la même ligne ; un autre id est refusé
/// (`422 JOURNAL_ID_MISMATCH`).
abstract final class JournalIds {
  static const Uuid _uuid = Uuid();

  static String entryId(JournalSeanceKey key) => _uuid.v5(
    key.coursId,
    'journal:${DateOnlyJsonHelper.toJson(key.date)}:'
    '${key.timeSlotId.toLowerCase()}',
  );
}
