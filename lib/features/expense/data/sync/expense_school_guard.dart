import 'package:school_app_flutter/core/offline/outbox_entry.dart';
import 'package:school_app_flutter/core/offline/outbox_sync_handler.dart';

/// Une écriture d'une AUTRE école du poste, rencontrée pendant la session de
/// celle-ci (le moteur ne filtre pas la file par école).
///
/// La pousser la ferait juger dans l'école de la session : un retrait y
/// rendrait 404 et serait abandonné, un contenu y serait refusé pour un type
/// inconnu — deux verdicts faux, le second terminal. Elle attend proprement
/// (`blocked` : ni tentative, ni poison) le retour de sa propre session.
///
/// `null` quand l'entrée peut partir — y compris quand l'une des deux écoles
/// est inconnue : dans le doute, ne jamais bloquer la synchro.
OutboxDispatchResult? expenseForeignSchoolHold(
  OutboxEntry entry,
  String? currentSchoolId,
) {
  final owner = entry.schoolId;
  if (owner == null || owner.isEmpty) return null;
  if (currentSchoolId == null || currentSchoolId.isEmpty) return null;
  if (owner == currentSchoolId) return null;
  return const OutboxDispatchResult.blocked(
    'Dépense d\'une autre école — attend la session de son école',
  );
}
