/// État d'une dépendance inter-agrégat (une arête du graphe de push).
///
/// Générique : ne connaît ni paiement ni discipline, seulement l'état **local**
/// de l'entité prérequise (l'inscription de l'élève référencé). Une seule règle,
/// lue à chaque tentative de push, partagée par toutes les arêtes réelles du
/// graphe (paiement→inscription, discipline→inscription) et par la future
/// note→évaluation. Cf. `SYNCHRO_Dependances_depends_on_V1` §2/§6 et
/// `SPEC_Moteur_Synchro_V1` §7.2.
enum OutboxDependencyState {
  /// Prérequis satisfait : l'entité est `SYNCED`, ou il n'existe aucune entité
  /// locale prérequise (élève préexistant du roster) → pousser.
  ready,

  /// Prérequis encore en vol (`DRAFT` / `PENDING_SYNC` / `PROVISIONAL`, aucun en
  /// échec) → outcome `blocked` : **attente PROPRE**, sans `attempts++`, sans
  /// backoff, sans poison. Se lève automatiquement à l'ACK du prérequis.
  waiting,

  /// Prérequis en échec **terminal** (`SYNC_ERROR`) → cascade : le dépendant est
  /// surfacé (outcome `failed`) au lieu de se re-différer indéfiniment. Le geste
  /// reste visible pour correction, il n'est jamais perdu.
  parentFailed,
}

/// Sonde d'état d'une dépendance de push, résolue par l'`studentId` **et
/// l'année scolaire** référencés par l'agrégat.
///
/// Le scope par année est **impératif** : un élève a plusieurs inscriptions
/// (cohorte N-1 pullée + réinscription N), et une inscription d'une AUTRE année
/// en échec/brouillon ne doit jamais bloquer un geste de l'année courante. Quand
/// l'année est inconnue (`academicYearId == null`, seulement possible côté
/// paiement où le champ est optionnel), la sonde retombe sur un scope
/// niveau-élève (moins précis, défensif).
///
/// Câblée en DI sur `EnrollmentReadDao.studentEnrollmentDependency`, injectée aux
/// handlers d'outbox (paiement, discipline) qui restent ainsi découplés du DAO
/// Inscription. Stubbable en test.
typedef OutboxDependencyGate =
    Future<OutboxDependencyState> Function(
      String studentId,
      String? academicYearId,
    );
