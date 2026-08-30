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
      phone_number TEXT NOT NULL,
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
/// `previous_balance_in_cents` remplace le REAL de la spec (règle argent).
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
      previous_balance_in_cents INTEGER NOT NULL DEFAULT 0,
      currency TEXT,
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
const TableSchema refFeeTariffsTable = TableSchema(
  name: 'ref_fee_tariffs',
  createTableSql: '''
    CREATE TABLE ref_fee_tariffs (
      id TEXT PRIMARY KEY,
      academic_year_id TEXT,
      school_level_id TEXT,
      school_level_group_id TEXT,
      fee_code TEXT NOT NULL,
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
const TableSchema paymentsTable = TableSchema(
  name: 'payments',
  createTableSql: '''
    CREATE TABLE payments (
      id TEXT PRIMARY KEY,
      client_uuid TEXT NOT NULL,
      student_id TEXT NOT NULL,
      academic_year_id TEXT,
      amount_in_cents INTEGER NOT NULL,
      currency TEXT NOT NULL,
      method TEXT NOT NULL DEFAULT 'CASH',
      paid_at TEXT NOT NULL,
      payer_first_name TEXT NOT NULL,
      payer_last_name TEXT NOT NULL,
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
const TableSchema paymentAllocationsTable = TableSchema(
  name: 'payment_allocations',
  createTableSql: '''
    CREATE TABLE payment_allocations (
      id TEXT PRIMARY KEY,
      client_uuid TEXT NOT NULL,
      payment_id TEXT NOT NULL,
      student_charge_id TEXT,
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
  refPreEnrollmentsTable,
  // Facturation
  refFeeTariffsTable,
  studentChargesTable,
  paymentsTable,
  paymentAllocationsTable,
  paymentAnomaliesTable,
  generatedDocumentsTable,
];
