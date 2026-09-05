/// La table de routage des retraits : une clé de ressource serveur → la table
/// locale à laquelle elle s'applique.
///
/// ## Pourquoi une table, ici, et une seule
///
/// Le serveur ne connaît pas le schéma sqflite : il nomme une **ressource**
/// (`finance_payments`), jamais une table (`payments`). La correspondance ne se
/// déduit d'aucune règle — cinq préfixes `ref_` n'existent que localement,
/// `attendance` désigne la séance et non la ligne d'appel, `editique_documents`
/// s'appelle ici `generated_documents`. Une translittération échouerait une fois
/// sur trois.
///
/// Cette table est **le seul endroit** du client qui sache retirer une ligne
/// venue d'un retrait serveur. C'est délibéré : le squelette de pagination, lui,
/// est recopié dans chaque dépôt de pull, et c'est précisément ce qui a fait
/// écarter l'idée d'un tableau `deletions` par flux — treize implantations,
/// treize occasions d'oublier une garde.
///
/// ## Ce qu'une entrée déclare
///
/// Le nom de la table, la colonne d'identité, et deux choses qui ne se devinent
/// pas : la colonne de **portée** (pour les retraits conditionnels) et la
/// colonne d'**état de synchronisation** (pour ne jamais effacer une écriture
/// locale non poussée). Les tables filles sont nommées explicitement — sqflite
/// n'applique aucune cascade.
library;

/// La table locale visée par un retrait, et ce qui garde son effacement.
class TombstoneTarget {
  /// La table locale à purger.
  final String table;

  /// La colonne portant l'identifiant serveur.
  final String idColumn;

  /// Colonne de portée, pour les retraits `OUT_OF_SCOPE` — l'enseignant qu'un
  /// cours vient de quitter, le type qu'une préinscription vient de quitter.
  ///
  /// `null` quand le flux n'a pas de portée déplaçable : un tel retrait
  /// conditionnel serait alors ignoré plutôt qu'appliqué au jugé.
  final String? scopeColumn;

  /// Colonne d'état de synchronisation, quand la table en porte une.
  ///
  /// Sa présence change la règle : une ligne qui n'est pas `SYNCED` porte une
  /// écriture que le poste n'a pas encore poussée, et l'effacer perdrait le
  /// travail de quelqu'un sans le dire. Les tables `ref_*`, elles, ne sont
  /// jamais écrites par l'interface et n'ont rien à protéger.
  final String? syncStatusColumn;

  /// Tables filles à purger d'abord, avec la colonne qui les rattache au parent.
  /// sqflite ne connaît pas les cascades : sans cette liste, un versement retiré
  /// laisserait ses imputations derrière lui, et la caisse continuerait de les
  /// compter.
  final Map<String, String> children;

  /// Descendants qui ne se rattachent pas au parent par une colonne — les notes
  /// d'un cours passent par ses évaluations. Chaque instruction reçoit un seul
  /// paramètre : l'identifiant du parent. Exécutées **avant** [children], donc
  /// des plus profonds vers les plus proches.
  final List<String> descendantsSql;

  /// Préfixes de clé de curseur scopés à cette ligne, à effacer avec elle.
  ///
  /// Déclarés en chaînes plutôt qu'importés des modules : ce fichier vit dans le
  /// socle, et lui faire dépendre de la couche métier pour trois constantes
  /// inverserait la dépendance qu'il existe à tenir.
  final List<String> scopedCursorPrefixes;

  /// L'identité tient dans le COUPLE (identifiant, portée), faute de clé de
  /// substitution côté client. Ce n'est alors pas une condition mais la seconde
  /// moitié de la clé — d'où un drapeau, et non l'absence de [scopeColumn].
  final bool pairedByScope;

  /// La table ne contient QUE des lignes de la portée retirée : la condition est
  /// donc déjà vraie du seul fait d'y être.
  ///
  /// `ref_pre_enrollments` n'accueille que des préinscriptions et ne porte aucune
  /// colonne de type. Un retrait conditionnel y serait ignoré faute de colonne à
  /// comparer — c'est-à-dire que la conversion d'une préinscription, le seul
  /// événement pour lequel ce flux existe, ne serait jamais appliquée.
  final bool scopeIsImplicit;

  const TombstoneTarget({
    required this.table,
    this.idColumn = 'id',
    this.scopeColumn,
    this.syncStatusColumn,
    this.children = const {},
    this.descendantsSql = const [],
    this.scopedCursorPrefixes = const [],
    this.pairedByScope = false,
    this.scopeIsImplicit = false,
  });
}

/// L'état d'une ligne écrite localement et pas encore acquittée par le serveur.
/// Le retrait ne touche que ce qui est `SYNCED`.
const String kSyncedStatus = 'SYNCED';

/// `resource` (clé serveur) → table locale.
///
/// Les ressources absentes sont ignorées **sans erreur** : le contrat prévoit
/// qu'un flux existe côté serveur avant que ce client sache le traiter, et un
/// retrait pour une table qu'on n'a pas est un non-événement, pas une panne.
const Map<String, TombstoneTarget> kTombstoneTargets = {
  // ── inscription, et l'identité qui voyage dans son agrégat ────────────────
  'enrollments': TombstoneTarget(
    table: 'enrollments',
    syncStatusColumn: 'sync_status',
  ),
  'students': TombstoneTarget(
    table: 'students',
    syncStatusColumn: 'sync_status',
  ),
  'parents': TombstoneTarget(table: 'parents', syncStatusColumn: 'sync_status'),
  // Le couple (élève, parent) tient dans (entityId, scopeKey) faute de clé de
  // substitution côté serveur : la portée n'est pas ici une condition, c'est la
  // seconde moitié de l'identité. Traité à part dans le DAO.
  'student_parent': TombstoneTarget(
    table: 'student_parent',
    idColumn: 'student_id',
    scopeColumn: 'parent_id',
    pairedByScope: true,
  ),
  'enrollment_pre_enrollments': TombstoneTarget(
    table: 'ref_pre_enrollments',
    scopeIsImplicit: true,
  ),

  // ── finance ───────────────────────────────────────────────────────────────
  'finance_payments': TombstoneTarget(
    table: 'payments',
    syncStatusColumn: 'sync_status',
    children: {
      'payment_allocations': 'payment_id',
      'payment_tenders': 'payment_id',
    },
  ),
  'finance_student_charges': TombstoneTarget(
    table: 'student_charges',
    syncStatusColumn: 'sync_status',
  ),
  // Clée localement par (enrollment_id, reduction_code) : le serveur envoie donc
  // le couple, et non l'identifiant de la ligne — que cette table ne porte pas.
  'enrollment_reductions': TombstoneTarget(
    table: 'enrollment_reductions',
    idColumn: 'enrollment_id',
    scopeColumn: 'reduction_code',
    pairedByScope: true,
  ),

  // ── classe ────────────────────────────────────────────────────────────────
  'classrooms': TombstoneTarget(table: 'ref_classrooms'),
  'classroom_members': TombstoneTarget(table: 'ref_classroom_members'),
  'classroom_transfers': TombstoneTarget(
    table: 'classroom_transfers',
    syncStatusColumn: 'sync_status',
  ),

  // ── présence & discipline ─────────────────────────────────────────────────
  'attendance': TombstoneTarget(
    table: 'attendance_sessions',
    syncStatusColumn: 'sync_status',
    children: {'attendance_records': 'session_id'},
  ),
  'disciplinary_cases': TombstoneTarget(
    table: 'disciplinary_cases',
    syncStatusColumn: 'sync_status',
    children: {'disciplinary_case_comments': 'disciplinary_case_id'},
  ),

  // ── emploi du temps ───────────────────────────────────────────────────────
  'schedule_time_slots': TombstoneTarget(table: 'ref_time_slots'),
  'schedule_sessions': TombstoneTarget(
    table: 'ref_recurring_sessions',
    scopeColumn: 'teacher_id',
  ),

  // ── notation ──────────────────────────────────────────────────────────────
  'academics_cours': TombstoneTarget(
    table: 'ref_cours',
    scopeColumn: 'teacher_id',
    // Un cours retiré emporte tout ce qui pend à lui. Les notes passent par les
    // évaluations : elles se suppriment donc en premier, et par sous-requête.
    descendantsSql: [
      'DELETE FROM note_evaluation WHERE evaluation_id IN '
          '(SELECT id FROM evaluation WHERE cours_id = ?)',
      'DELETE FROM evaluation WHERE cours_id = ?',
      'DELETE FROM ref_chapitre WHERE cours_id = ?',
    ],
    // Sans cette purge, un cours réaffecté PUIS rendu reprendrait un curseur
    // périmé au lieu de rebootstraper, et perdrait en silence tout ce qui
    // existait avant l'éviction.
    scopedCursorPrefixes: ['academics_evaluations', 'academics_notes'],
  ),
  'academics_evaluations': TombstoneTarget(
    table: 'evaluation',
    scopeColumn: 'cours_id',
    syncStatusColumn: 'sync_status',
  ),
  'academics_notes': TombstoneTarget(
    table: 'note_evaluation',
    scopeColumn: 'evaluation_id',
    syncStatusColumn: 'sync_status',
  ),

  // ── éditique & boutique ───────────────────────────────────────────────────
  // Les octets de la pièce vivent dans un cache à part : sans cette purge, un
  // document retiré laisserait son PDF sur l'appareil, servi par le numéro.
  'editique_documents': TombstoneTarget(
    table: 'generated_documents',
    children: {'editique_cache_entries': 'document_id'},
  ),
  'boutique_sales': TombstoneTarget(
    table: 'boutique_sales',
    syncStatusColumn: 'sync_status',
    children: {
      'boutique_sale_lines': 'sale_id',
      'boutique_sale_tenders': 'sale_id',
    },
  ),
};
