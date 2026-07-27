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
/// et `email` sont NULL hors-ligne (« en cours d'attribution »), remplis à l'ACK.
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
    'CREATE INDEX idx_students_phone ON students(phone_number)',
    'CREATE INDEX idx_students_names ON students(last_name, first_name)',
    'CREATE INDEX idx_students_dob ON students(date_of_birth)',
  ],
);

/// `parents` — tuteurs. Clé naturelle = `phone_number` (get-or-create local pour
/// la fratrie sur une même tablette). `identification_number` reste NULL en
/// local (le serveur génère `PID-…`). L'`id` provisoire est remappé vers le
/// canonique serveur à l'ACK.
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
  createIndexSql: ['CREATE INDEX idx_parents_phone ON parents(phone_number)'],
);

/// `student_parent` — lien N-N élève ↔ tuteur, porteur du `relationship_type`.
const TableSchema studentParentTable = TableSchema(
  name: 'student_parent',
  createTableSql: '''
    CREATE TABLE student_parent (
      student_id TEXT NOT NULL,
      parent_id TEXT NOT NULL,
      relationship_type TEXT NOT NULL DEFAULT 'OTHER',
      PRIMARY KEY (student_id, parent_id)
    )
  ''',
);

/// `enrollments` — dossiers d'inscription (uuid client). `enrollment_date` =
/// date terrain honorée serveur. `enrollment_code` rempli à l'ACK.
/// `source_ref` = référence d'origine du dossier (contrat agrégat) : matricule
/// (RE_ENROLLMENT), id de préinscription (PRE_ENROLLMENT), NULL (NEW).
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
/// pré-sélectionne l'année active hors-ligne.
const TableSchema refAcademicYearsTable = TableSchema(
  name: 'ref_academic_years',
  createTableSql: '''
    CREATE TABLE ref_academic_years (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      start_date TEXT,
      end_date TEXT,
      is_current INTEGER NOT NULL DEFAULT 0,
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
      status TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error TEXT,
      synced_at INTEGER,
      updated_at INTEGER NOT NULL DEFAULT 0
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
const List<TableSchema> enrollmentFinanceOfflineTables = [
  studentsTable,
  parentsTable,
  studentParentTable,
  enrollmentsTable,
  // Inscription — tables de référence (pull, lecture seule)
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
  generatedDocumentsTable,
];
