import 'package:school_app_flutter/core/database/table_schema.dart';

/// Contribution de schéma de la branche offline **Notes / Cours** (module
/// `academics` + `schedule`).
///
/// Point d'extension purement additif : cette liste est insérée dans
/// `buildOfflineSchema()` (offline_schema.dart) via `...academicsOfflineTables`.
/// C'est le SEUL fichier de schéma que cette branche possède — le socle n'est
/// jamais réécrit (conflit de merge réduit à une ligne d'import + un spread).
///
/// Aligné sur `SCHEMA_sqflite_Notes_V1.md` (tables back réelles `time_slot`,
/// `recurring_session`, `cours`, `evaluation`, `note_evaluation`) et sur la
/// frontière ADR-006 (le calcul d'ensemble — moyenne officielle, rang, bulletin,
/// résultats « live » — reste serveur ; seuls la SAISIE et sa RÉFÉRENCE vont
/// offline).
///
/// Tables :
/// - `ref_time_slots`         — trame horaire de l'école (réf, lecture seule).
/// - `ref_recurring_sessions` — remplissage hebdomadaire (labels dénormalisés).
/// - `ref_cours`              — le cours = classe × ligne de barème × prof (réf).
/// - `evaluation`             — évaluation, insert-only, uuid honoré (régime A).
/// - `note_evaluation`        — note, upsert clé naturelle + LWW (régime C).
/// - `ref_branche`/`ref_ligne_bareme`/`ref_chapitre`/`ref_periode`/
///   `ref_sous_periode` — bundle `grades-referential` (ETag, remplacement
///   d'ensemble) : branches, plafonds de saisie, chapitres, statut de clôture.
///
/// Conventions (identiques aux autres branches) :
/// - enums en TEXT, valeurs exactes SCREAMING_SNAKE.
/// - `updated_at` = horloge client (epoch ms), arbitre du last-write-wins.
/// - `synced_at`  = fraîcheur (ADR-002), distinct de `updated_at`.
/// - `server_updated_at` = temps de visibilité serveur (base du pull keyset,
///   ADR-008) ; nullable, posé au pull / à l'ACK. Le curseur de pull lui-même
///   reste un jeton opaque dans `sync_meta`.
/// - pas de `school_id` local (tablette mono-établissement, scope serveur via
///   le token / le query param métier).

/// `ref_time_slots` — trame horaire de l'école (créneaux de sonnerie). Réf pure,
/// lecture seule, rafraîchie par pull conditionnel. `start_time`/`end_time` en
/// TEXT « HH:mm » (pas de type TIME en sqflite). `slot_order` = ordre métier
/// d'affichage (le pull keyset trie serveur par `server_updated_at`, le client
/// re-trie par `slot_order`).
const TableSchema refTimeSlotsTable = TableSchema(
  name: 'ref_time_slots',
  createTableSql: '''
    CREATE TABLE ref_time_slots (
      id TEXT PRIMARY KEY,
      slot_order INTEGER NOT NULL,
      start_time TEXT NOT NULL,
      end_time TEXT NOT NULL,
      label TEXT,
      server_updated_at INTEGER,
      synced_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_time_slots_order ON ref_time_slots(slot_order)',
  ],
);

/// `ref_recurring_sessions` — remplissage hebdomadaire récurrent de l'emploi du
/// temps. Labels **dénormalisés** (`teacher_label`, `classroom_label`,
/// `subject_label`) pour un affichage sans jointure. `day_of_week` = MON…SAT.
const TableSchema refRecurringSessionsTable = TableSchema(
  name: 'ref_recurring_sessions',
  createTableSql: '''
    CREATE TABLE ref_recurring_sessions (
      id TEXT PRIMARY KEY,
      academic_year_id TEXT NOT NULL,
      cours_id TEXT NOT NULL,
      time_slot_id TEXT NOT NULL,
      day_of_week TEXT NOT NULL,
      room TEXT,
      teacher_id TEXT NOT NULL,
      classroom_id TEXT NOT NULL,
      teacher_label TEXT NOT NULL,
      classroom_label TEXT NOT NULL,
      subject_label TEXT NOT NULL,
      server_updated_at INTEGER,
      synced_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_sessions_classroom '
        'ON ref_recurring_sessions(classroom_id)',
    'CREATE INDEX idx_sessions_teacher ON ref_recurring_sessions(teacher_id)',
    'CREATE INDEX idx_sessions_day_slot '
        'ON ref_recurring_sessions(day_of_week, time_slot_id)',
  ],
);

/// `ref_cours` — le cours au sens back : une **ligne de barème enseignée dans
/// UNE classe** (clé serveur `(classroom_id, ligne_bareme_id)`). `classroom_id`
/// donne le roster (via `ref_classroom_members`, module Classe) ; `ligne_bareme_id`
/// est le pont vers le poste de bulletin (calcul serveur, pas la saisie offline).
/// Réf, lecture seule.
const TableSchema refCoursTable = TableSchema(
  name: 'ref_cours',
  createTableSql: '''
    CREATE TABLE ref_cours (
      id TEXT PRIMARY KEY,
      classroom_id TEXT NOT NULL,
      ligne_bareme_id TEXT NOT NULL,
      teacher_id TEXT,
      server_updated_at INTEGER,
      synced_at INTEGER NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_cours_classroom ON ref_cours(classroom_id)',
  ],
);

/// `evaluation` — évaluation créée offline. **Régime A** : insert-only, uuid
/// client honoré (`ON CONFLICT (id) DO NOTHING` côté serveur). Immuable après
/// création. `eval_date` en epoch ms ; `max_points` REAL ; `poids` > 0. Un des
/// deux rattachements temporels est posé selon le `type` : `sous_periode_id`
/// (INTERRO/DEVOIR) ou `periode_scolaire_id` (EXAMEN).
const TableSchema evaluationTable = TableSchema(
  name: 'evaluation',
  createTableSql: '''
    CREATE TABLE evaluation (
      id TEXT PRIMARY KEY,
      cours_id TEXT NOT NULL,
      type TEXT NOT NULL,
      eval_date INTEGER NOT NULL,
      max_points REAL NOT NULL,
      poids INTEGER NOT NULL,
      sous_periode_id TEXT,
      periode_scolaire_id TEXT,
      updated_at INTEGER NOT NULL,
      server_updated_at INTEGER,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      synced_at INTEGER,
      chapitre_ids_json TEXT NOT NULL DEFAULT '[]',
      rejection_code TEXT
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_evaluation_cours ON evaluation(cours_id)',
    'CREATE INDEX idx_evaluation_sync ON evaluation(sync_status)',
  ],
);

/// `note_evaluation` — note saisie offline. **Régime C** : upsert sur la clé
/// naturelle `(evaluation_id, student_id)` + last-write-wins arbitré par
/// `updated_at`. `points_obtenus` REAL (NULL si absent ; note exacte, jamais de
/// la monnaie) ; `statut` ∈ NOTEE | ABSENT_JUSTIFIE | ABSENT_NON_JUSTIFIE |
/// EN_ATTENTE. Write-heavy → push en lot (agrégat par évaluation).
const TableSchema noteEvaluationTable = TableSchema(
  name: 'note_evaluation',
  createTableSql: '''
    CREATE TABLE note_evaluation (
      id TEXT PRIMARY KEY,
      evaluation_id TEXT NOT NULL,
      student_id TEXT NOT NULL,
      points_obtenus REAL,
      statut TEXT NOT NULL,
      updated_at INTEGER NOT NULL,
      server_updated_at INTEGER,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      synced_at INTEGER,
      rejection_reason TEXT,
      UNIQUE (evaluation_id, student_id)
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_note_evaluation ON note_evaluation(evaluation_id)',
    'CREATE INDEX idx_note_sync ON note_evaluation(sync_status)',
  ],
);

/// `ref_cours_notation` — **RETIRÉE (v12)** : squelette du détail de notation
/// d'un cours (arbre période → sous-période + statut, workaround alimenté en
/// réutilisant un endpoint ONLINE), remplacé par le bundle `grades-referential`
/// (`ref_periode`/`ref_sous_periode`, 100% local — cf. `CourseOfflineRepositoryImpl.
/// getCoursNotationDetail`). Définition **conservée** pour que l'étape de
/// migration `v8→v9` (qui la crée pour les bases pré-v9) reste rejouable ; la
/// table reste présente mais inerte, purgée par la migration `v11→v12`. Aucun
/// DAO ne la lit/l'écrit plus.
const TableSchema refCoursNotationTable = TableSchema(
  name: 'ref_cours_notation',
  createTableSql: '''
    CREATE TABLE ref_cours_notation (
      cours_id TEXT PRIMARY KEY,
      classroom_id TEXT,
      branche_nom TEXT,
      effectif INTEGER NOT NULL DEFAULT 0,
      periodes_json TEXT NOT NULL,
      server_updated_at INTEGER,
      synced_at INTEGER NOT NULL
    )
  ''',
);

/// `ref_branche` — branche académique (bundle `grades-referential`, réf,
/// lecture seule). Remplacement d'ensemble à chaque pull (pas de delta).
const TableSchema refBrancheTable = TableSchema(
  name: 'ref_branche',
  createTableSql: '''
    CREATE TABLE ref_branche (
      id TEXT PRIMARY KEY,
      nom TEXT NOT NULL,
      code TEXT
    )
  ''',
);

/// `ref_ligne_bareme` — plafonds de saisie (`max_journalier_par_sous_periode`,
/// `max_examen_par_periode_scolaire` **NULLABLE** = branche sans examen, jamais
/// traité comme 0) + pont vers la branche. Bundle `grades-referential`, réf,
/// lecture seule.
const TableSchema refLigneBaremeTable = TableSchema(
  name: 'ref_ligne_bareme',
  createTableSql: '''
    CREATE TABLE ref_ligne_bareme (
      id TEXT PRIMARY KEY,
      grille_id TEXT NOT NULL,
      rubrique_id TEXT NOT NULL,
      branche_id TEXT NOT NULL,
      ordre INTEGER NOT NULL DEFAULT 0,
      max_journalier_par_sous_periode INTEGER NOT NULL,
      max_examen_par_periode_scolaire INTEGER
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_ligne_bareme_branche ON ref_ligne_bareme(branche_id)',
  ],
);

/// `ref_chapitre` — chapitre d'un cours, cochable à la création d'évaluation
/// (`contenu` volontairement omis du bundle). Bundle `grades-referential`, réf,
/// lecture seule.
const TableSchema refChapitreTable = TableSchema(
  name: 'ref_chapitre',
  createTableSql: '''
    CREATE TABLE ref_chapitre (
      id TEXT PRIMARY KEY,
      cours_id TEXT NOT NULL,
      titre TEXT NOT NULL,
      ordre INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_chapitre_cours ON ref_chapitre(cours_id)',
  ],
);

/// `ref_periode` — période scolaire à plat (statut de clôture, portée
/// année × groupe de niveau). Bundle `grades-referential`, réf, lecture seule —
/// **seule** source du statut de clôture (remplace le squelette
/// `ref_cours_notation`, retiré).
const TableSchema refPeriodeTable = TableSchema(
  name: 'ref_periode',
  createTableSql: '''
    CREATE TABLE ref_periode (
      id TEXT PRIMARY KEY,
      academic_year_id TEXT NOT NULL,
      school_level_group_id TEXT NOT NULL,
      ordre INTEGER NOT NULL DEFAULT 0,
      statut TEXT NOT NULL,
      start_date TEXT,
      end_date TEXT
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_periode_group '
        'ON ref_periode(academic_year_id, school_level_group_id)',
  ],
);

/// `ref_sous_periode` — sous-période à plat (lien parent + statut de clôture).
/// Bundle `grades-referential`, réf, lecture seule.
const TableSchema refSousPeriodeTable = TableSchema(
  name: 'ref_sous_periode',
  createTableSql: '''
    CREATE TABLE ref_sous_periode (
      id TEXT PRIMARY KEY,
      periode_scolaire_id TEXT NOT NULL,
      ordre INTEGER NOT NULL DEFAULT 0,
      statut TEXT NOT NULL,
      start_date TEXT,
      end_date TEXT
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_sous_periode_parent '
        'ON ref_sous_periode(periode_scolaire_id)',
  ],
);

/// Contribution de schéma de la branche Notes / Cours, insérée dans
/// `buildOfflineSchema()`.
const List<TableSchema> academicsOfflineTables = [
  refTimeSlotsTable,
  refRecurringSessionsTable,
  refCoursTable,
  evaluationTable,
  noteEvaluationTable,
  refCoursNotationTable,
  refBrancheTable,
  refLigneBaremeTable,
  refChapitreTable,
  refPeriodeTable,
  refSousPeriodeTable,
];
