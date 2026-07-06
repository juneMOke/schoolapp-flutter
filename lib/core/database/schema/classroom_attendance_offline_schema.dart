import 'package:school_app_flutter/core/database/table_schema.dart';

/// Contribution de schéma de la branche offline **Classe + Présence/Discipline**.
///
/// Point d'extension purement additif : cette liste est insérée dans
/// `buildOfflineSchema()` (offline_schema.dart) via `...classroomAttendanceOfflineTables`.
/// C'est le SEUL fichier de schéma que cette branche possède — le socle n'est
/// jamais réécrit (conflit de merge réduit à une ligne d'import + un spread).
///
/// Tables :
/// - `ref_classrooms`         — référence des classes (compteurs pré-agrégés serveur).
/// - `ref_classroom_members`  — roster nominatif dénormalisé (partagé avec Présence).
/// - `attendance_records`     — appels locaux, stockage par exception (LWW).
/// - `disciplinary_cases`     — cas disciplinaires locaux (fait insert-only + traitement LWW).
///
/// Conventions :
/// - enums en TEXT, valeurs exactes SCREAMING_SNAKE.
/// - `updated_at` = horloge client (epoch ms), arbitre du last-write-wins.
/// - `synced_at`  = fraîcheur (ADR-002), distinct de `updated_at`.
/// - pas de `school_id` local (tablette mono-établissement, scope serveur via token).

/// `ref_classrooms` — classes reçues du pull (CF1). Compteurs pré-agrégés serveur.
/// ⚠️ Ne jamais supposer `total_count = female_count + male_count` : le genre
/// OTHER est compté dans `total_count` sans compteur dédié.
const TableSchema refClassroomsTable = TableSchema(
  name: 'ref_classrooms',
  createTableSql: '''
    CREATE TABLE ref_classrooms (
      id TEXT PRIMARY KEY,
      academic_year_id TEXT NOT NULL,
      school_level_group_id TEXT,
      school_level_id TEXT,
      name TEXT NOT NULL,
      capacity INTEGER,
      grille_id TEXT,
      teacher_id TEXT,
      teacher_first_name TEXT,
      teacher_last_name TEXT,
      teacher_middle_name TEXT,
      total_count INTEGER NOT NULL DEFAULT 0,
      female_count INTEGER NOT NULL DEFAULT 0,
      male_count INTEGER NOT NULL DEFAULT 0,
      version INTEGER,
      updated_at INTEGER,
      synced_at INTEGER
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_classrooms_year_level '
        'ON ref_classrooms(academic_year_id, school_level_id)',
  ],
);

/// `ref_classroom_members` — roster nominatif dénormalisé (CF1). Produit par
/// Classe, consommé par Présence (roster local partagé). `status` filtre l'ACTIVE.
const TableSchema refClassroomMembersTable = TableSchema(
  name: 'ref_classroom_members',
  createTableSql: '''
    CREATE TABLE ref_classroom_members (
      id TEXT PRIMARY KEY,
      student_id TEXT NOT NULL,
      classroom_id TEXT NOT NULL,
      academic_year_id TEXT NOT NULL,
      student_first_name TEXT NOT NULL,
      student_last_name TEXT NOT NULL,
      student_middle_name TEXT,
      student_gender TEXT NOT NULL DEFAULT 'OTHER',
      status TEXT NOT NULL DEFAULT 'ACTIVE',
      version INTEGER,
      updated_at INTEGER,
      synced_at INTEGER
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_ref_members_classroom_status '
        'ON ref_classroom_members(classroom_id, status)',
    'CREATE INDEX idx_ref_members_year '
        'ON ref_classroom_members(academic_year_id)',
  ],
);

/// `attendance_records` — appels locaux (AF-1). Stockage par exception :
/// seuls les absents (ou les retards corrigés) portent une ligne ; un élève
/// sans ligne pour la date = présent. `updated_at` arbitre le last-write-wins.
/// Clé naturelle `(student_id, attendance_date, academic_year_id)`.
const TableSchema attendanceRecordsTable = TableSchema(
  name: 'attendance_records',
  createTableSql: '''
    CREATE TABLE attendance_records (
      id TEXT PRIMARY KEY,
      student_id TEXT NOT NULL,
      student_first_name TEXT NOT NULL,
      student_last_name TEXT NOT NULL,
      student_middle_name TEXT,
      student_gender TEXT NOT NULL DEFAULT 'OTHER',
      classroom_id TEXT NOT NULL,
      attendance_date TEXT NOT NULL,
      academic_year_id TEXT NOT NULL,
      present INTEGER NOT NULL DEFAULT 1,
      absence_reason TEXT,
      absence_reason_note TEXT,
      version INTEGER,
      updated_at INTEGER NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      synced_at INTEGER,
      UNIQUE (student_id, attendance_date, academic_year_id)
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_attendance_class_date '
        'ON attendance_records(classroom_id, attendance_date, academic_year_id)',
  ],
);

/// `disciplinary_cases` — cas disciplinaires locaux (DF-1). `content` SENSIBLE
/// (base entièrement chiffrée SQLCipher). Le FAIT (immuable) + le TRAITEMENT
/// (status/sanction, LWW `updated_at`). `id` = uuid client honoré (idempotence).
/// `disciplinary_case_date` conservé localement (le back ne le renvoie pas).
const TableSchema disciplinaryCasesTable = TableSchema(
  name: 'disciplinary_cases',
  createTableSql: '''
    CREATE TABLE disciplinary_cases (
      id TEXT PRIMARY KEY,
      student_id TEXT NOT NULL,
      student_first_name TEXT NOT NULL,
      student_last_name TEXT NOT NULL,
      student_middle_name TEXT,
      student_gender TEXT NOT NULL DEFAULT 'OTHER',
      academic_year_id TEXT NOT NULL,
      disciplinary_case_date TEXT NOT NULL,
      title TEXT NOT NULL,
      content TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'DISRUPTIVE_BEHAVIOR',
      severity TEXT NOT NULL DEFAULT 'MINOR',
      status TEXT NOT NULL DEFAULT 'OPEN',
      sanction TEXT,
      version INTEGER,
      updated_at INTEGER NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      synced_at INTEGER
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_disc_student_year '
        'ON disciplinary_cases(student_id, academic_year_id)',
  ],
);

/// Toutes les tables de la branche Classe + Présence/Discipline.
const List<TableSchema> classroomAttendanceOfflineTables = [
  refClassroomsTable,
  refClassroomMembersTable,
  attendanceRecordsTable,
  disciplinaryCasesTable,
];
