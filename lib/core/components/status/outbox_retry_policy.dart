import 'package:school_app_flutter/core/offline/outbox_author.dart';

/// Le rejeu manuel republie le payload **gelé à l'enfilage**, tel quel.
///
/// Pour six des sept agrégats c'est sans danger : le serveur est idempotent par
/// clé métier (rejeu = get-or-return, aucune écriture) ou fait un upsert par clé
/// naturelle sans jamais rien supprimer.
///
/// `ATTENDANCE` est la seule exception, et elle est structurelle : le contrat
/// déclare la liste d'absences **exhaustive** et le serveur réconcilie **par
/// différence** — ce qui est en base et pas dans le payload est SUPPRIMÉ. Un
/// payload gelé porte la photo du jour au moment de l'enfilage : le rejouer plus
/// tard détruit côté serveur toute absence ajoutée depuis (autre poste, back
/// office), et toute absence rétablie localement entre-temps.
///
/// Le rejeu de la présence n'est donc pas « rejouer » mais « recomposer depuis
/// l'état local courant du jour, puis pousser » — un chemin qui doit passer par
/// le repository présence, pas par la file. Tant qu'il n'existe pas, on refuse
/// le geste plutôt que de proposer un bouton qui détruit des données.
bool canRequeueFrozenPayload(String aggregateType) =>
    aggregateType != 'ATTENDANCE';

/// Vrai si le porteur courant peut réellement rejouer [entry] LUI-MÊME.
///
/// Deux conditions, et la seconde vient d'un geste qui se retournait contre
/// l'utilisateur : rejouer l'écriture d'un AUTRE compte la fait repasser
/// `PENDING`, ce qui vide `errorCount`, fait quitter `syncConflict` à la
/// pastille — et, avant que la file retenue ne devienne atteignable, rendait
/// la feuille elle-même inaccessible. Un clic bien intentionné faisait passer
/// l'état de « bloqué et visible » à « bloqué et invisible ». Et il ne pouvait
/// rien débloquer : la garde d'attribution du moteur reporte immédiatement
/// l'entrée, puisque le serveur refuserait l'écriture d'autrui.
///
/// L'entrée reste AFFICHÉE — c'est son bouton qui disparaît, remplacé par
/// l'explication de qui doit la reprendre.
bool canRetryEntry({
  required String aggregateType,
  required String payload,
  required String? currentUid,
}) =>
    canRequeueFrozenPayload(aggregateType) &&
    !isForeignOutboxAuthor(payload, currentUid);
