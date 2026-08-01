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
