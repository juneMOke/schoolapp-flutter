import 'package:school_app_flutter/core/database/table_schema.dart';

/// Tables sqflite de la branche offline **Inscription + Facturation**.
///
/// Point d'extension additif : cette liste est « spreadée » dans
/// `buildOfflineSchema()` (cf. offline_schema.dart). Aucune contrainte
/// FOREIGN KEY n'est déclarée (comme l'outbox du socle) : l'intégrité est
/// maintenue par la couche applicative, et les tables peuvent être insérées
/// dans n'importe quel ordre côté tests (ffi) comme en production (SQLCipher).
///
/// Conventions verrouillées :
/// - ids = uuid client honorés serveur (idempotence) ;
/// - argent = `INTEGER` centimes + `currency` (jamais de flottant) ;
/// - deux axes distincts : `sync_status` (technique) ≠ `status` (métier) ;
/// - matricule/email NULL hors-ligne, remplis à l'ACK ;
/// - enums en TEXT, valeurs exactes SCREAMING_SNAKE du back.

// ── Inscription ──────────────────────────────────────────────────────────────

/// `students` — élèves saisis localement (uuid client). `matriculation_number`
/// est NULL hors-ligne (« en cours d'attribution »), rempli à l'ACK.
///
/// ⚠️ `phone_number` et `email` sont **inertes depuis la v27** : plus rien ne
/// les écrit, et la migration a effacé ce qui était déjà descendu. Ils portaient
/// de la donnée personnelle qu'aucune requête ne lisait et que le mapper vers
/// l'écran abandonnait (`StudentDetail` ne les déclare pas) — elle descendait du
/// pull hydratant et dormait sur chaque tablette. Les colonnes restent déclarées
/// parce que SQLite ne sait pas en retirer une sans reconstruire la table, et
/// `students` est la source de Facturation, du Contrôle des frais, de Documents
/// et du ticket imprimé : le gain ne vaut pas le risque.
///
/// Le tuteur, lui, garde son téléphone (`parents.phone_number`) — c'est la clé
/// d'unicité applicative du rapprochement RE/PRE, pas un contact dormant.
/// Facultatif depuis la v45, mais toujours une clé **quand il est là** : ce qui
/// change est ce qui arrive quand il manque, pas ce qu'il vaut quand il est
/// renseigné.
const TableSchema studentsTable = TableSchema(
  name: 'students',
  createTableSql: '''
    CREATE TABLE students (
      id TEXT PRIMARY KEY,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      surname TEXT,
      gender TEXT NOT NULL,
      date_of_birth TEXT NOT NULL,
      birth_place TEXT,
      nationality TEXT,
      city TEXT,
      district TEXT,
      municipality TEXT,
      neighborhood TEXT,
      address TEXT,
      phone_number TEXT,
      matriculation_number TEXT,
      email TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error TEXT,
      synced_at INTEGER,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    // Pas d'index sur `phone_number` (retiré v27) : il portait sur une colonne
    // qu'aucune requête n'interrogeait — du coût d'écriture pur à chaque élève.
    'CREATE INDEX idx_students_names ON students(last_name, first_name)',
    'CREATE INDEX idx_students_dob ON students(date_of_birth)',
  ],
);

/// `parents` — tuteurs. DEUX chemins d'écriture coexistent (aucune contrainte
/// SQL UNIQUE sur `phone_number` — unicité volontairement APPLICATIVE, DAO) :
/// - RE/PRE (`seedDraft`) : `upsertParentByPhone`, `phone_number` reste la
///   clé naturelle (get-or-create local pour la fratrie sur une même
///   tablette) ;
/// - étape Tuteurs interactive (wizard) : `upsertDraftGuardianParent`, upsert
///   PAR ID stable + garde stricte (`ParentPhoneConflictException` si un
///   AUTRE parent porte déjà ce téléphone) — la fusion silencieuse par
///   téléphone n'existe PAS sur ce chemin.
/// **`phone_number` est NULLABLE (v45)**, à l'image de la V117 serveur. Un
/// tuteur sans numéro existe au guichet : le parent qui n'a pas de ligne, celui
/// qui vient inscrire l'enfant d'un frère, celui dont le numéro viendra plus
/// tard. La contrainte ne laissait qu'une issue — en inventer un — c'est-à-dire
/// une saisie fausse, et un message envoyé à un inconnu le jour où l'école
/// notifie. Le modèle tolérait déjà l'élève SANS AUCUN tuteur ; « tuteur sans
/// numéro » restait, seul, irreprésentable.
///
/// `NULL`, **jamais `''` et surtout jamais un placeholder**. Le serveur détaille
/// pourquoi côté Postgres — un placeholder n'y est unique qu'une fois dans toute
/// la base — mais la raison qui vaut ICI est plus simple et pire : le
/// rapprochement local compare des numéros, et une valeur partagée fusionnerait
/// tous les tuteurs sans numéro dans UNE fiche.
///
/// ⚠️ **Ce que l'absence retire.** Le téléphone n'est pas un contact dormant,
/// c'est la clé d'unicité applicative du rapprochement RE/PRE. Sans lui, le
/// tuteur n'a plus de clé : il est rapproché par son nom complet **à l'intérieur
/// du dossier de son élève**, et jamais au-delà (cf. `findGuardianWithoutPhone`,
/// miroir du `GuardianMatcher` serveur). Conséquence à assumer au guichet — un
/// tuteur sans numéro **n'est jamais partagé avec la fratrie**. C'est
/// précisément ce que le téléphone prouvait et que son absence ne prouve plus.
///
/// `identification_number` reste NULL en local (le serveur génère `PID-…`).
/// L'`id` provisoire est remappé vers le canonique serveur à l'ACK.
const TableSchema parentsTable = TableSchema(
  name: 'parents',
  createTableSql: '''
    CREATE TABLE parents (
      id TEXT PRIMARY KEY,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      surname TEXT,
      phone_number TEXT,
      email TEXT,
      identification_number TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      synced_at INTEGER,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    // `idx_parents_phone` ne porte plus les rapprochements de tuteurs :
    // ceux-ci comparent une clé normalisée (`PhoneNumberSql.matchKey`) pour
    // reconnaître un même numéro écrit autrement, ce qu'un index sur la
    // valeur brute ne peut pas servir. Conservé faute de justifier un
    // palier de schéma à lui seul.
    'CREATE INDEX idx_parents_phone ON parents(phone_number)',
    'CREATE INDEX idx_parents_names ON parents(last_name, first_name)',
  ],
);

/// `student_parent` — lien N-N élève ↔ tuteur, porteur du `relationship_type`
/// et du drapeau `emergency_contact`.
///
/// Les deux décrivent le COUPLE (élève, tuteur), jamais le tuteur seul : un
/// tuteur est rapproché par téléphone, donc une même ligne `parents` sert toute
/// une fratrie. Posé sur `parents`, « contact d'urgence » désignerait le même
/// adulte pour tous les enfants de ce tuteur.
///
/// L'index unique PARTIEL tient l'invariant « au plus un contact d'urgence par
/// élève » — miroir de `ux_emergency_contact_per_student` côté serveur (V101).
/// Partiel, jamais contrainte unique : seules les lignes à 1 sont concernées,
/// les tuteurs ordinaires (0) restent en nombre quelconque. Il est le FILET,
/// pas la règle : le DAO démote puis promeut dans la même transaction, et
/// l'index n'a le dernier mot que sur une écriture qui aurait échappé à ce
/// chemin.
const TableSchema studentParentTable = TableSchema(
  name: 'student_parent',
  createTableSql: '''
    CREATE TABLE student_parent (
      student_id TEXT NOT NULL,
      parent_id TEXT NOT NULL,
      relationship_type TEXT NOT NULL DEFAULT 'OTHER',
      emergency_contact INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (student_id, parent_id)
    )
  ''',
  createIndexSql: [
    'CREATE UNIQUE INDEX ux_emergency_contact_per_student '
        'ON student_parent(student_id) WHERE emergency_contact = 1',
  ],
);

/// `enrollments` — dossiers d'inscription (uuid client). `enrollment_date` =
/// date terrain honorée serveur. `enrollment_code` rempli à l'ACK.
/// `source_ref` = référence d'origine du dossier (contrat agrégat) : matricule
/// (RE_ENROLLMENT), id de préinscription (PRE_ENROLLMENT), NULL (NEW).
///
/// `former_student` — le « nouveau / ancien » du formulaire, au sens « déjà
/// élève de CETTE école ». **Délibérément distinct d'`enrollment_type`** :
/// l'enum décrit le chemin technique suivi par le dossier, ce drapeau un fait
/// déclaré au guichet. Les deux divergent dès qu'une école démarre sur
/// l'application — tous ses anciens élèves y entrent en NEW_ENROLLMENT, faute
/// de dossier N-1. NOT NULL, comme la colonne serveur.
///
/// `medical_notes` — texte libre sur la santé de l'enfant (allergies,
/// traitement en cours, conduite à tenir). Porté par l'INSCRIPTION et non par
/// l'élève : côté serveur `saveStudent` est un get-or-return, une note posée
/// sur `students` serait figée à vie dès la première saisie. Donnée de santé :
/// jamais journalisée, jamais imprimée.
const TableSchema enrollmentsTable = TableSchema(
  name: 'enrollments',
  createTableSql: '''
    CREATE TABLE enrollments (
      id TEXT PRIMARY KEY,
      student_id TEXT NOT NULL,
      enrollment_type TEXT NOT NULL,
      status TEXT NOT NULL,
      academic_year_id TEXT NOT NULL,
      school_level_id TEXT,
      school_level_group_id TEXT,
      enrollment_date TEXT NOT NULL,
      enrollment_code TEXT,
      source_ref TEXT,
      previous_school_name TEXT,
      previous_academic_year TEXT,
      previous_school_level_group TEXT,
      previous_school_level TEXT,
      previous_school_level_id TEXT,
      previous_rate REAL,
      previous_rank INTEGER,
      validated_previous_year INTEGER,
      former_student INTEGER NOT NULL DEFAULT 0,
      medical_notes TEXT,
      transfer_reason TEXT,
      cancellation_reason TEXT,
      emit_document INTEGER NOT NULL DEFAULT 1,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error TEXT,
      synced_at INTEGER,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_enrollments_sync_status ON enrollments(sync_status)',
    'CREATE INDEX idx_enrollments_student ON enrollments(student_id)',
  ],
);

// ── Inscription — tables de référence (pull, lecture seule) ──────────────────
// Peuplées par les pulls delta (curseur `updatedSince` ISO via `sync_meta`) ;
// jamais écrites par l'UI. Conventions locales conservées vs
// `SCHEMA_sqflite_Inscription_V1` (écarts assumés et documentés) :
// - dates « humaines » en TEXT ISO (comme `students`/`enrollments`), pas INTEGER ;
// - horodatages machine (`synced_at`, `updated_at`) en INTEGER ;
// - argent en INTEGER centimes (`*_in_cents`), jamais REAL (cf. règle argent).

/// `ref_academic_years` — années scolaires pré-synchronisées (D1). `is_current`
/// pré-sélectionne l'année active hors-ligne. `school_id` (stampé côté client
/// depuis `CurrentUserContext`, pas depuis le payload serveur) scope la
/// résolution courante/précédente par école — nécessaire sur un device
/// multi-écoles (bootstrap remplacé, cf. décision FRONT).
const TableSchema refAcademicYearsTable = TableSchema(
  name: 'ref_academic_years',
  createTableSql: '''
    CREATE TABLE ref_academic_years (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      start_date TEXT,
      end_date TEXT,
      is_current INTEGER NOT NULL DEFAULT 0,
      school_id TEXT NOT NULL DEFAULT '',
      synced_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_academic_years_school '
        'ON ref_academic_years(school_id)',
  ],
);

/// `ref_school` — identité de l'école (tenant), cache mono-ligne (D5/D6 :
/// racine du bundle, pas dupliquée par année). Réécrite en entier à chaque
/// pull référentiel (`upsertReferential` purge puis réinsère).
const TableSchema refSchoolTable = TableSchema(
  name: 'ref_school',
  createTableSql: '''
    CREATE TABLE ref_school (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      country TEXT,
      city TEXT,
      district TEXT,
      municipality TEXT,
      address TEXT,
      phone TEXT,
      email TEXT,
      synced_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
);

/// `ref_school_level_groups` — CYCLES (D1). `period_type` = pont vers l'Académique
/// (trimestre/semestre).
const TableSchema refSchoolLevelGroupsTable = TableSchema(
  name: 'ref_school_level_groups',
  createTableSql: '''
    CREATE TABLE ref_school_level_groups (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      code TEXT NOT NULL,
      period_type TEXT,
      academic_year_id TEXT NOT NULL,
      display_order INTEGER NOT NULL DEFAULT 0,
      synced_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_school_level_groups_year '
        'ON ref_school_level_groups(academic_year_id)',
  ],
);

/// `ref_school_levels` — NIVEAUX (D9 : l'élève s'inscrit dans un niveau, pas une
/// classe). `split_into_classrooms` pilote la répartition (module Classe).
const TableSchema refSchoolLevelsTable = TableSchema(
  name: 'ref_school_levels',
  createTableSql: '''
    CREATE TABLE ref_school_levels (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      code TEXT NOT NULL,
      display_order INTEGER NOT NULL DEFAULT 0,
      level_group_id TEXT NOT NULL,
      split_into_classrooms INTEGER NOT NULL DEFAULT 0,
      synced_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_school_levels_group '
        'ON ref_school_levels(level_group_id)',
  ],
);

/// `ref_previous_year_students` — **cohorte de réinscription** (D3) : élèves N-1,
/// bornée/statique + snapshot arriérés. `student_id` = id CANONIQUE réutilisé par
/// le nouvel `enrollment` (cas RE) → aucun doublon d'élève.
/// Les arriérés N-1 vivent dans `ref_previous_year_student_balances` — une
/// ligne PAR DEVISE. Ils tenaient ici en `previous_balance_in_cents` +
/// `currency` : un scalaire étiqueté de la devise du premier poste, qui
/// annonçait « 90 425,00 $ » à un élève devant 425,00 $ et 90 000 FC.
///
/// `medical_notes` est la fiche santé du dossier N-1, descendue pour que le
/// guichet n'ait pas à la ressaisir. C'est une **proposition** : elle ne devient
/// la valeur de la nouvelle inscription que si le poste la repousse dans son
/// agrégat. Un canal qui la lit sans la renvoyer perd les allergies de l'enfant
/// à chaque changement d'année.
const TableSchema refPreviousYearStudentsTable = TableSchema(
  name: 'ref_previous_year_students',
  createTableSql: '''
    CREATE TABLE ref_previous_year_students (
      student_id TEXT PRIMARY KEY,
      matriculation_number TEXT NOT NULL,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      surname TEXT,
      gender TEXT NOT NULL,
      date_of_birth TEXT NOT NULL,
      birth_place TEXT,
      previous_academic_year_id TEXT,
      previous_school_level_id TEXT,
      previous_classroom_id TEXT,
      guardian_name TEXT,
      guardian_phone TEXT,
      medical_notes TEXT,
      synced_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_previous_year_students_matricule '
        'ON ref_previous_year_students(matriculation_number)',
    'CREATE INDEX idx_ref_previous_year_students_name '
        'ON ref_previous_year_students(last_name, surname)',
  ],
);

/// `ref_previous_year_student_balances` — arriérés N-1, **une ligne par devise**.
///
/// Table fille plutôt qu'une colonne JSON : la cohorte se re-seede par lots, et
/// un JSON obligerait à relire-modifier-réécrire une chaîne à chaque pull, là où
/// une table fille se remplace par `DELETE` + `INSERT` sous le même index que le
/// reste du seed.
///
/// **Aucune ligne = ne doit rien**, et jamais un zéro dans une unité que
/// personne n'a choisie. C'est la même règle que la liste vide du contrat.
const TableSchema refPreviousYearStudentBalancesTable = TableSchema(
  name: 'ref_previous_year_student_balances',
  createTableSql: '''
    CREATE TABLE ref_previous_year_student_balances (
      student_id TEXT NOT NULL,
      currency TEXT NOT NULL,
      amount_in_cents INTEGER NOT NULL,
      PRIMARY KEY (student_id, currency)
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_prev_year_balances_student '
        'ON ref_previous_year_student_balances(student_id)',
  ],
);

/// `ref_pre_enrollments` — snapshot des préinscriptions en ligne (D4 : online-first,
/// repli Pré→Première sans synchro). Delta opportuniste : `updated_at` = curseur.
const TableSchema refPreEnrollmentsTable = TableSchema(
  name: 'ref_pre_enrollments',
  createTableSql: '''
    CREATE TABLE ref_pre_enrollments (
      id TEXT PRIMARY KEY,
      first_name TEXT NOT NULL,
      last_name TEXT NOT NULL,
      surname TEXT,
      gender TEXT,
      date_of_birth TEXT,
      birth_place TEXT,
      desired_school_level_id TEXT,
      guardian_name TEXT,
      guardian_phone TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0,
      synced_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_pre_enrollments_phone '
        'ON ref_pre_enrollments(guardian_phone)',
  ],
);

// ── Facturation ──────────────────────────────────────────────────────────────

/// `ref_fee_tariffs` — grille tarifaire (référentiel gelé sur la saison).
/// Montants en centimes. `version` pour le verrou optimiste / delta.
///
/// `code` (v39) est ce qui distingue deux lignes de **même nature** sur un même
/// niveau : « T1 » et « T2 » d'un minerval étalé, « INFO » et « BIBLI » de deux
/// frais scolaires. Le serveur l'admet depuis V94 et le sert déjà dans le
/// bundle référentiel ; le front le jetait, si bien que sept tranches de
/// minerval s'affichaient sept fois « Minerval ».
///
/// ⚠️ **Nullable, et jamais vide en base côté serveur.** Le serveur retombe sur
/// la NATURE quand l'école ne saisit rien (`FeeTariffService.codeOuDefaut`) :
/// un code qui vaut `fee_code` ne distingue donc rien et ne s'affiche pas. La
/// colonne, elle, reste nullable pour les bases d'avant ce palier et pour un
/// serveur qui ne servirait pas encore le champ.
const TableSchema refFeeTariffsTable = TableSchema(
  name: 'ref_fee_tariffs',
  createTableSql: '''
    CREATE TABLE ref_fee_tariffs (
      id TEXT PRIMARY KEY,
      academic_year_id TEXT,
      school_level_id TEXT,
      school_level_group_id TEXT,
      fee_code TEXT NOT NULL,
      code TEXT,
      label TEXT NOT NULL,
      amount_in_cents INTEGER NOT NULL,
      currency TEXT NOT NULL,
      due_at TEXT,
      version INTEGER NOT NULL DEFAULT 0,
      synced_at INTEGER,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_fee_tariffs_level ON ref_fee_tariffs(school_level_id)',
  ],
);

/// `ref_exchange_rates` — le taux de guichet paramétré par l'école, en série.
///
/// ⚠️ **Une série, jamais une valeur remplacée en place.** Une école qui change
/// de taux à midi n'est pas un cas d'école à Kinshasa, et un versement encaissé
/// hors ligne remonte parfois trois jours plus tard : on lit le taux qui valait
/// à `paid_at`, pas celui d'aujourd'hui. D'où `effective_from` dans la clé.
///
/// **`rate_micros`, entier, jamais un `REAL`.** Le serveur stocke
/// `numeric(18,6)` — six décimales, c'est exactement une micro-unité. Un
/// flottant qui traverserait la couche métier finirait par arrondir de l'argent,
/// et ici il l'arrondirait avant même de l'écrire. Même règle que
/// `amount_in_cents`, pour la même raison. Le `REAL` de
/// [refReductionLinesTable] ne s'applique pas : un pourcentage n'est pas un
/// facteur monétaire.
///
/// **`base` est la devise de la CRÉANCE, `quote` la devise REÇUE.** Le pivot est
/// la créance et non une référence unique de l'école : c'est la seule
/// orientation qui rende l'invariant perçu/imputé vérifiable sans table de
/// passage.
///
/// **Pas d'`id` : le serveur n'en donne pas** — même choix que
/// [refReductionTypesTable]. L'identité d'un taux est sa paire dans son école à
/// sa date ; un id local fabriqué depuis ce quadruplet n'aurait rien identifié
/// de plus et aurait laissé croire qu'il venait du contrat.
///
/// **`school_id` n'est pas décoratif.** Dix flux portent déjà un curseur non
/// scopé sur cette base ; un taux d'une école servi à la tablette d'une autre
/// est un défaut d'argent, pas d'affichage. Il est stampé depuis
/// `CurrentUserContext`, jamais depuis le payload.
///
/// `divergence_band_bp` est la bande de tolérance en points de base (200 = 2 %)
/// paramétrée par l'école. `NULL` = « non communiquée » : le contrôle retombe
/// alors sur le défaut de l'appelant, jamais sur zéro, qui signalerait tout.
const TableSchema refExchangeRatesTable = TableSchema(
  name: 'ref_exchange_rates',
  createTableSql: '''
    CREATE TABLE ref_exchange_rates (
      school_id TEXT NOT NULL DEFAULT '',
      base TEXT NOT NULL,
      quote TEXT NOT NULL,
      effective_from TEXT NOT NULL,
      rate_micros INTEGER NOT NULL,
      divergence_band_bp INTEGER,
      set_by TEXT,
      synced_at INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (school_id, base, quote, effective_from)
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_exchange_rates_pair '
        'ON ref_exchange_rates(school_id, base, quote, effective_from)',
  ],
);

/// `ref_fee_code_sections` — le **titre** que l'école donne à chaque nature de
/// frais (V115 serveur, `GET /finance/fee-codes`).
///
/// ## Un cache d'AFFICHAGE, et rien d'autre
///
/// Aucune écriture ne lit cette table. Le `code` qui part sur le fil vient
/// toujours de la créance ou de la grille, **jamais d'ici** — c'est ce qui
/// distingue ce cache du catalogue que `CONFIGURATION_PLAN.md` D-9 refuse de
/// persister : là-bas, un catalogue vieilli alimenterait une écriture et sa
/// divergence n'apparaîtrait qu'en 422, sur l'activation. Ici, un titre périmé
/// affiche un ancien nom pendant un cycle de pull, et c'est tout ce qu'il peut
/// faire.
///
/// **Pourquoi persister plutôt que garder en session** : `loadFeeCodes` n'est
/// appelé que depuis Configuration, et le repository qui porte le cache est un
/// lazy singleton. Le cache est donc froid pour un caissier — l'utilisateur du
/// détail Facturation. Sans cette table, la fiche d'un élève afficherait le
/// titre de l'école ou la nature localisée selon qu'on est passé ou non par
/// Configuration dans la session.
///
/// **`active` est stocké et ne filtre RIEN ici.** Masquer une section dit « ne
/// me la propose plus à la saisie », jamais « ne sais plus la nommer » : une
/// créance posée sur une nature depuis masquée doit garder son titre. C'est le
/// piège que `SECTIONS_FRAIS_PLAN.md` §3 a déjà rencontré sur le panneau des
/// tarifs, et le pull passe pour cette raison par `includeHidden: true`.
///
/// **Pas d'`id`, comme [refReductionTypesTable]** : le serveur n'en donne pas.
/// L'identité d'une section est son code dans son école, et c'est la clé
/// primaire.
///
/// **`school_id` n'est pas décoratif** : sur une tablette partagée, le titre
/// d'une école servi à l'autre est un contresens d'affichage sur une pièce
/// d'argent. Il est stampé depuis `CurrentUserContext`, jamais depuis le
/// payload.
const TableSchema refFeeCodeSectionsTable = TableSchema(
  name: 'ref_fee_code_sections',
  createTableSql: '''
    CREATE TABLE ref_fee_code_sections (
      school_id TEXT NOT NULL DEFAULT '',
      code TEXT NOT NULL,
      label TEXT NOT NULL,
      active INTEGER NOT NULL DEFAULT 1,
      sort_order INTEGER NOT NULL DEFAULT 0,
      synced_at INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (school_id, code)
    )
  ''',
  createIndexSql: [],
);

/// `ref_reduction_types` — catalogue des natures de réduction (ADR-021 V1).
///
/// ⚠️ **Pas d'`academic_year_id`, et c'est structurel** : le barème descend à la
/// RACINE du bundle référentiel, à côté de `school`, pas dans un slot d'année.
/// La purge du pull ne peut donc PAS être scopée par année comme celle de
/// [refFeeTariffsTable] — elle est scopée par **école**, et `school_id` est
/// stampé depuis `CurrentUserContext`, jamais depuis le payload. Sans ce scope,
/// un pull effacerait le barème de l'autre école sur une tablette partagée, et
/// aucun filtre `academic_year_id` ne viendrait masquer la perte en « vide ».
///
/// **Aucun `id` : le serveur n'en donne pas.** `ReductionSummaryDto` ne porte
/// que `code`, `label`, `active` et ses lignes — l'identité d'un type est son
/// code dans son école, et c'est la clé primaire. Un id local fabriqué depuis
/// ce couple n'aurait rien identifié de plus, et aurait laissé croire qu'il
/// venait du contrat.
const TableSchema refReductionTypesTable = TableSchema(
  name: 'ref_reduction_types',
  createTableSql: '''
    CREATE TABLE ref_reduction_types (
      school_id TEXT NOT NULL DEFAULT '',
      code TEXT NOT NULL,
      label TEXT NOT NULL,
      active INTEGER NOT NULL DEFAULT 1,
      synced_at INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (school_id, code)
    )
  ''',
  createIndexSql: [],
);

/// `ref_reduction_lines` — le barème proprement dit : ce qu'une nature réduit,
/// et de combien, rubrique par rubrique.
///
/// `percentage` est un pourcentage (0–100), pas de l'argent : d'où le `REAL`,
/// qui ne contredit pas la règle « argent = INTEGER centimes ». Rien ne le
/// calcule en V1 — le front stocke ce qui descend sans le réinterpréter, et
/// l'arrondi reste un problème de V2, déjà tranché côté back (HALF_UP au
/// centime).
///
/// La table est peuplée alors que **presque rien ne la lit en V1** : seul le
/// filtre « ne proposer que les types qui réduisent réellement quelque chose »
/// s'y appuie. C'est délibéré — la section descend de toute façon, et la jeter
/// maintenant coûterait un palier de plus à la V2.
///
/// **Table à plat, section imbriquée sur le fil.** Le serveur sert les lignes
/// DANS leur type (`reductions[].lines[]`) et n'en donne ni id ni code de
/// rattachement : le code du parent est stampé ici à l'aplatissement. Deux
/// listes à joindre côté client seraient deux occasions de les désynchroniser —
/// c'est la raison que le back donne lui-même de l'imbrication.
///
/// Clé : `(school_id, reduction_code, fee_code)`, comme la contrainte du back.
const TableSchema refReductionLinesTable = TableSchema(
  name: 'ref_reduction_lines',
  createTableSql: '''
    CREATE TABLE ref_reduction_lines (
      school_id TEXT NOT NULL DEFAULT '',
      reduction_code TEXT NOT NULL,
      fee_code TEXT NOT NULL,
      percentage REAL NOT NULL,
      synced_at INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (school_id, reduction_code, fee_code)
    )
  ''',
  createIndexSql: [],
);

/// `enrollment_reductions` — qui a droit à quoi. **Mémoire seule en V1** :
/// aucune créance n'en tient compte, aucun montant n'en dépend.
///
/// Pas de `sync_status` : cette table n'a **pas de flux propre**. Les codes
/// voyagent dans l'agrégat d'inscription (`reductionCodes`), le serveur grave
/// l'octroi et le renvoie — exactement le régime des créances. Rien n'est
/// jamais poussé depuis ici, donc rien n'a à porter d'état de synchro.
///
/// ⚠️ Corollaire à retenir pour la V2 : côté serveur, poser un octroi ne touche
/// PAS `enrollments.server_updated_at`. En V1 c'est sans effet — l'octroi est
/// simultané à l'inscription, la ligne est neuve de toute façon. Dès que
/// l'octroi se détachera, il sera invisible à notre pull sans flux à lui.
const TableSchema enrollmentReductionsTable = TableSchema(
  name: 'enrollment_reductions',
  createTableSql: '''
    CREATE TABLE enrollment_reductions (
      enrollment_id TEXT NOT NULL,
      reduction_code TEXT NOT NULL,
      updated_at INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (enrollment_id, reduction_code)
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_enrollment_reductions_enrollment '
        'ON enrollment_reductions(enrollment_id)',
  ],
);

/// `student_charges` — grand-livre de créances. `amount_paid_in_cents`/`status`
/// sont AUTORITAIRES (écrits UNIQUEMENT par le pull ou l'ACK). Le solde
/// optimiste d'affichage est porté à part par `optimistic_paid_in_cents`
/// (encaissement local), jamais confondu avec l'autoritaire (FF-Lot 6).
const TableSchema studentChargesTable = TableSchema(
  name: 'student_charges',
  createTableSql: '''
    CREATE TABLE student_charges (
      id TEXT PRIMARY KEY,
      student_id TEXT NOT NULL,
      academic_year_id TEXT,
      school_level_id TEXT,
      school_level_group_id TEXT,
      fee_tariff_id TEXT,
      fee_code TEXT NOT NULL,
      label TEXT NOT NULL,
      expected_amount_in_cents INTEGER NOT NULL,
      amount_paid_in_cents INTEGER NOT NULL DEFAULT 0,
      optimistic_paid_in_cents INTEGER NOT NULL DEFAULT 0,
      currency TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'DUE',
      due_at TEXT,
      version INTEGER NOT NULL DEFAULT 0,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      synced_at INTEGER,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_student_charges_student ON student_charges(student_id)',
    'CREATE INDEX idx_student_charges_student_fee '
        'ON student_charges(student_id, fee_code)',
  ],
);

/// `payments` — événements de paiement append-only (money-grade). `id` = uuid
/// client honoré serveur ; `client_uuid` = même valeur (clé d'idempotence).
/// `paid_at` = date terrain honorée. Montants en centimes.
///
/// **Caissier et appareil (v19, ADR-012 RG-012-7/11)** : le ticket provisoire
/// est une projection déterministe de cette ligne, il doit donc pouvoir nommer
/// qui a encaissé, même des mois plus tard et sur une tablette partagée. Le nom
/// est DÉNORMALISÉ à côté de l'uid : `OutboxAuthorDirectory.identityOf` peut
/// rendre `null`, et l'entrée d'outbox qui portait l'auteur est supprimée dès
/// l'ACK — l'uid seul ne suffirait pas à réimprimer un ticket à l'identique.
///
/// **`receipt_id` (v19)** : UUID de la pièce scellée, renvoyé par le serveur
/// dans l'ACK de push ET dans le delta de pull. Seule clé permettant de
/// re-télécharger un reçu définitif par `GET /editique/documents/{id}`.
///
/// **Les quatre colonnes de payeur sont NULLABLES (v43).** Elles l'étaient déjà
/// côté serveur depuis sa V10 — c'était l'arête HTTP, et elle seule, qui
/// exigeait un nom et un prénom. Cette exigence se payait comptant au guichet :
/// la file attend pendant qu'on demande son état civil à qui tend les billets,
/// et le guichetier finit par taper « X ». Un champ qui a l'air renseigné et ne
/// désigne personne est strictement pire qu'un champ vide. Les imputations
/// nomment toujours l'élève et les créances soldées : c'est là qu'est
/// l'imputabilité, pas dans le nom de qui a tendu l'argent.
///
/// Elles portent `NULL`, **jamais `''`** : « pas de payeur » est un fait, pas un
/// nom de longueur zéro, et seul `NULL` se lit sans ambiguïté « rien à
/// afficher ». Un repli sur `''` rendrait « pas de nom » indiscernable de « nom
/// inconnu » au moment précis où l'annuaire doit choisir entre proposer ce
/// payeur et le taire.
///
/// **`payer_phone_number` (v28)** : numéro E.164 du payeur, saisi au guichet.
/// NULLABLE alors que la saisie l'exige — la colonne décrit aussi le passé :
/// tout versement antérieur à la v28 et tout versement encaissé sur un poste
/// resté en arrière n'en portent aucun, et le pull ne peut pas en inventer. Un
/// `NOT NULL` aurait donc obligé à replier sur `''`, c'est-à-dire à rendre
/// « pas de numéro » indiscernable de « numéro inconnu » au moment précis où
/// l'écran doit choisir entre proposer ce payeur et le taire.
///
/// **`collected_by_id` / `collected_by_name` (v29)** : l'encaisseur tel que le
/// SERVEUR l'attribue, distinct des `cashier_*` que ce poste stampe lui-même
/// (v19). Les deux nomment la même personne quand le versement a été encaissé
/// ICI ; seul le second existe quand il vient d'un autre guichet, cas où les
/// `cashier_*` restent nuls parce qu'aucun poste local n'a rien observé.
///
/// Ils ne sont pas fusionnés en une seule paire de colonnes, et c'est
/// délibéré : `cashier_*` est ce qui a été IMPRIMÉ sur le ticket de ce poste
/// (RG-012-11), une trace que nul delta ne doit pouvoir réécrire. Les remplir
/// depuis le pull reviendrait à laisser le serveur changer après coup le nom
/// que le guichetier a remis au payeur sur papier.
///
/// C'est la SEULE donnée personnelle qu'on rajoute au repos après le ménage de
/// la v27 (`students.phone_number`/`email` effacés). La différence est sa
/// destination : celle-ci est lue — elle remonte au serveur avec le versement
/// et alimente l'annuaire de payeurs du guichet. La v27 n'a pas proscrit la
/// PII, elle a proscrit la PII que personne ne lit.
/// Les montants ne sont **pas** ici, et c'est le même choix que côté serveur :
/// `amount_in_cents` + `currency` n'ont jamais été des propriétés du versement,
/// seulement un résumé de ses imputations — qu'on pouvait stocker en scalaire
/// tant qu'il n'y avait qu'une devise. Un passage au guichet qui solde une
/// créance en dollars et une en francs n'a pas de montant unique.
///
/// Ils se dérivent de `payment_allocations`, dont la devise est NOT NULL depuis
/// la création de la table. Le contrat de pull porte d'ailleurs la même
/// garantie sur chaque imputation, « ce qui permet à un client de reconstruire
/// le total par devise sans faire confiance à `amounts` ».
const TableSchema paymentsTable = TableSchema(
  name: 'payments',
  createTableSql: '''
    CREATE TABLE payments (
      id TEXT PRIMARY KEY,
      client_uuid TEXT NOT NULL,
      student_id TEXT NOT NULL,
      academic_year_id TEXT,
      method TEXT NOT NULL DEFAULT 'CASH',
      paid_at TEXT NOT NULL,
      payer_first_name TEXT,
      payer_last_name TEXT,
      payer_middle_name TEXT,
      payer_phone_number TEXT,
      status TEXT,
      cashier_uid TEXT,
      cashier_first_name TEXT,
      cashier_last_name TEXT,
      collected_by_id TEXT,
      collected_by_name TEXT,
      device_id TEXT,
      receipt_id TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error TEXT,
      synced_at INTEGER,
      updated_at INTEGER NOT NULL DEFAULT 0,
      ticket_printed_at INTEGER
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_payments_student ON payments(student_id)',
    'CREATE INDEX idx_payments_client_uuid ON payments(client_uuid)',
  ],
);

/// `payment_allocations` — imputations d'un paiement sur des créances.
/// Append-only immuable → PAS de `version`. `student_charge_id` peut pointer une
/// créance réelle, provisoire, ou être NULL (avance / trop-perçu).
///
/// `fee_tariff_id` (v38) désigne la **ligne de grille** payée. Depuis que le
/// serveur admet plusieurs lignes d'une même nature sur un niveau (minerval en
/// tranches), `fee_code` ne départage plus deux créances : c'est le tarif qui le
/// fait, et il est de meilleure autorité que `student_charge_id` — un tarif vient
/// toujours du référentiel servi par le serveur, il ne peut jamais être
/// provisoire. Nullable : une créance *ad hoc*, hors grille, n'en a pas.
const TableSchema paymentAllocationsTable = TableSchema(
  name: 'payment_allocations',
  createTableSql: '''
    CREATE TABLE payment_allocations (
      id TEXT PRIMARY KEY,
      client_uuid TEXT NOT NULL,
      payment_id TEXT NOT NULL,
      student_charge_id TEXT,
      fee_tariff_id TEXT,
      fee_code TEXT NOT NULL,
      student_charge_label TEXT NOT NULL,
      amount_in_cents INTEGER NOT NULL,
      currency TEXT NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_payment_allocations_payment '
        'ON payment_allocations(payment_id)',
    'CREATE INDEX idx_payment_allocations_charge '
        'ON payment_allocations(student_charge_id)',
  ],
);

/// `payment_tenders` — ce qui est **entré dans le tiroir** pour un versement.
///
/// Sœur de [paymentAllocationsTable], à la même profondeur : une **liste**, pas
/// un scalaire. Un parent peut tendre des dollars et des francs dans la même
/// main, et deux créances de devises différentes imposent deux lignes de toute
/// façon — c'est le modèle qui découpe, pas le geste du payeur.
///
/// Append-only immuable → **PAS de `version`**, comme les imputations.
///
/// ## Les deux axes, et pourquoi ils ne se confondent pas
///
/// L'imputation répond à « combien de sa dette a-t-il éteint », dans la devise
/// de la **créance**. Le tender répond à « qu'est-ce qui est entré dans le
/// tiroir », dans la devise **reçue**. Jusqu'ici les deux se confondaient parce
/// qu'ils étaient toujours dans la même unité ; le jour où un franc règle un
/// dollar, la caisse annoncerait des dollars sur une journée où le tiroir n'a vu
/// que des francs.
///
/// ## `amount_in_cents` est le **net conservé**, jamais le montant présenté
///
/// 120 000 tendus, 5 000 rendus : on écrit 115 000. Sans cette règle, le total
/// de caisse ne retombera jamais sur le comptage du tiroir, et le rapprochement
/// de la V3 héritera d'un historique inexploitable.
///
/// ## `rate_micros` et `pivot_currency`
///
/// Le taux de guichet **gelé**, en micro-unités entières (`numeric(18,6)` côté
/// serveur ; un flottant arrondirait de l'argent). `1 000 000` = taux 1, le cas
/// où perçu et imputé se confondent — c'est ce que porte tout l'historique
/// backfillé. `pivot_currency` est la devise de la **créance** contre laquelle
/// ce taux s'applique : elle lève l'ambiguïté quand un versement porte deux
/// devises reçues et deux devises de créance.
///
/// ## Aucun lien vers l'allocation, et c'est délibéré
///
/// Un versement de 112 000 FC qui solde 40 $ et 50 $ n'a pas comporté, dans la
/// réalité, un paquet de billets pour l'un et un paquet pour l'autre. Stocker
/// une correspondance enregistrerait une **proration comme si c'était une
/// observation** — or une proration se recalcule (`allocation × taux`), elle ne
/// se conserve pas.
const TableSchema paymentTendersTable = TableSchema(
  name: 'payment_tenders',
  createTableSql: '''
    CREATE TABLE payment_tenders (
      id TEXT PRIMARY KEY,
      client_uuid TEXT NOT NULL,
      payment_id TEXT NOT NULL,
      amount_in_cents INTEGER NOT NULL,
      currency TEXT NOT NULL,
      rate_micros INTEGER NOT NULL DEFAULT 1000000,
      pivot_currency TEXT NOT NULL
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_payment_tenders_payment '
        'ON payment_tenders(payment_id)',
  ],
);

// ── Documents (partagé Inscription / Facturation) ────────────────────────────

/// `generated_documents` — éditique provisoire → définitive. Sert les deux
/// domaines (`doc_domain` = ENROLLMENT|PAYMENT). `PROV-…` offline remplacé par
/// `ETL-…` scellé au sync (+ `verification_token`).
const TableSchema generatedDocumentsTable = TableSchema(
  name: 'generated_documents',
  createTableSql: '''
    CREATE TABLE generated_documents (
      id TEXT PRIMARY KEY,
      doc_domain TEXT NOT NULL,
      enrollment_id TEXT,
      payment_id TEXT,
      student_id TEXT,
      doc_type TEXT NOT NULL,
      number TEXT NOT NULL,
      provisional_number TEXT,
      status TEXT NOT NULL DEFAULT 'PROVISIONAL',
      verification_token TEXT,
      pdf_blob BLOB,
      created_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_generated_documents_enrollment '
        'ON generated_documents(enrollment_id)',
    'CREATE INDEX idx_generated_documents_payment '
        'ON generated_documents(payment_id)',
  ],
);

/// Toutes les tables de la branche offline Inscription + Facturation.
/// `payment_anomalies` — anomalies de synchro d'un encaissement (ADR-012 D-5,
/// **amendé**).
///
/// L'ADR parlait d'un état `REJETÉ`. Le contrat de synchro garantit l'inverse :
/// « le serveur ne rejette JAMAIS un paiement pour un motif métier — l'argent a
/// été physiquement reçu au guichet ». Un trop-perçu est ACCEPTÉ, le reçu
/// définitif est scellé, et seul un `overpayment` est signalé pour arbitrage.
/// L'issue terminale n'est donc pas un rejet mais une **anomalie**, et le ticket
/// remis au parent reste valide.
///
/// Table DÉDIÉE, et surtout **pas** l'outbox : une entrée d'outbox acquittée est
/// physiquement supprimée à la fin du flush (`deleteAcked`), et son motif
/// d'erreur est effacé par un simple clic sur « Réessayer » (`requeue`). Une
/// anomalie doit survivre aux deux et ne disparaître que sur un accusé explicite
/// — d'où `acknowledged_at` / `acknowledged_by`.
///
/// Montants en centimes. `device_id` et le caissier sont recopiés depuis le
/// paiement : l'anomalie doit rester lisible même si la ligne source évolue, et
/// RG-012-16 exige de savoir QUELLE tablette a encaissé.
const TableSchema paymentAnomaliesTable = TableSchema(
  name: 'payment_anomalies',
  createTableSql: '''
    CREATE TABLE payment_anomalies (
      id TEXT PRIMARY KEY,
      payment_id TEXT NOT NULL,
      student_id TEXT,
      kind TEXT NOT NULL,
      excess_in_cents INTEGER,
      currency TEXT,
      fee_code TEXT,
      reason TEXT,
      cashier_first_name TEXT,
      cashier_last_name TEXT,
      device_id TEXT,
      detected_at INTEGER NOT NULL,
      acknowledged_at INTEGER,
      acknowledged_by TEXT
    )
  ''',
  createIndexSql: [
    'CREATE UNIQUE INDEX idx_payment_anomalies_payment '
        'ON payment_anomalies(payment_id, kind)',
    'CREATE INDEX idx_payment_anomalies_open '
        'ON payment_anomalies(acknowledged_at)',
  ],
);

const List<TableSchema> enrollmentFinanceOfflineTables = [
  studentsTable,
  parentsTable,
  studentParentTable,
  enrollmentsTable,
  // Inscription — tables de référence (pull, lecture seule)
  refSchoolTable,
  refAcademicYearsTable,
  refSchoolLevelGroupsTable,
  refSchoolLevelsTable,
  refPreviousYearStudentsTable,
  refPreviousYearStudentBalancesTable,
  refPreEnrollmentsTable,
  // Facturation
  refFeeTariffsTable,
  refFeeCodeSectionsTable,
  refExchangeRatesTable,
  refReductionTypesTable,
  refReductionLinesTable,
  enrollmentReductionsTable,
  studentChargesTable,
  paymentsTable,
  paymentAllocationsTable,
  paymentTendersTable,
  paymentAnomaliesTable,
  generatedDocumentsTable,
];
