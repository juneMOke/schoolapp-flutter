/// Tables de la Paie du personnel (module Ressources humaines, sous-module C).
///
/// La tablette **calcule pour afficher**, le serveur **recalcule pour figer** :
/// avant validation, une ligne du livre n'existe nulle part — elle se calcule
/// à la lecture à partir des faits ci-dessous. Après validation, elle descend
/// figée (`payroll_lines`) et le calcul local ne tourne plus sur ce mois.
///
/// Tout descend sous `hr.pay.read`. Huit écritures remontent par la file :
/// réglages, profil de paie, éléments variables, geste du circuit, avance et
/// son annulation, versement et son annulation.
library;

import 'package:school_app_flutter/core/database/table_schema.dart';

/// `ref_payroll_settings` — les réglages de paie d'une école : diviseur
/// mensuel, majoration en ‰, statuts ouvrant les allocations, et par devise
/// l'allocation par enfant, le taux d'heure sup. par défaut et son pas.
///
/// Descend avec le socle ; modifiés sur la tablette, ils remontent par la file
/// (dernier écrit gagne) et le socle ne les écrase pas tant qu'ils ne sont pas
/// accusés. Absents = défauts.
const TableSchema refPayrollSettingsTable = TableSchema(
  name: 'ref_payroll_settings',
  createTableSql: '''
    CREATE TABLE ref_payroll_settings (
      school_id TEXT PRIMARY KEY,
      monthly_hours_divisor INTEGER NOT NULL,
      overtime_multiplier_permille INTEGER NOT NULL,
      allowance_eligible_kinds TEXT NOT NULL,
      by_currency TEXT NOT NULL,
      client_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error TEXT,
      sync_error_code TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
);

/// `staff_pay_profiles` — le profil de paie d'un agent : enfants à charge,
/// mode de versement préféré, opérateur et numéro de mobile money, banque.
/// Une donnée de paie, pas de la fiche : le secrétariat ne la lit pas.
const TableSchema staffPayProfilesTable = TableSchema(
  name: 'staff_pay_profiles',
  createTableSql: '''
    CREATE TABLE staff_pay_profiles (
      staff_member_id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      dependent_children INTEGER NOT NULL DEFAULT 0,
      preferred_mode TEXT,
      operator TEXT,
      payout_phone TEXT,
      bank_name TEXT,
      bank_account TEXT,
      client_updated_at TEXT NOT NULL,
      server_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error TEXT,
      sync_error_code TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_pay_profiles_school '
        'ON staff_pay_profiles(school_id)',
  ],
);

/// `payrolls` — l'état **serveur** d'une paie mensuelle, tel que le flux ou
/// un accusé l'a donné. Ce que la tablette a fait depuis vit dans
/// `payroll_gestures` et l'emporte à l'affichage tant que ce n'est pas accusé.
///
/// - `id` : uuid5 de (école, `"payroll:" + YYYY-MM`) — deux postes convergent.
/// - `validation_gesture_id` : le VALIDATE en vigueur, recopié tel quel dans
///   un versement ; `null` hors `VALIDATED`.
const TableSchema payrollsTable = TableSchema(
  name: 'payrolls',
  createTableSql: '''
    CREATE TABLE payrolls (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      month TEXT NOT NULL,
      status TEXT NOT NULL,
      submitted_at TEXT,
      submitted_by_name TEXT,
      validated_at TEXT,
      validated_by_name TEXT,
      return_reason TEXT,
      validation_gesture_id TEXT,
      server_updated_at TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE UNIQUE INDEX idx_payrolls_school_month '
        'ON payrolls(school_id, month)',
  ],
);

/// `payroll_variables` — les éléments variables d'un agent pour un mois :
/// minutes d'heures sup., taux horaire imposé, enfants à charge du mois.
/// Dernier écrit gagne ; écrits seulement sur une paie en brouillon.
const TableSchema payrollVariablesTable = TableSchema(
  name: 'payroll_variables',
  createTableSql: '''
    CREATE TABLE payroll_variables (
      school_id TEXT NOT NULL,
      month TEXT NOT NULL,
      staff_member_id TEXT NOT NULL,
      overtime_minutes INTEGER,
      overtime_rate_in_cents INTEGER,
      dependent_children INTEGER,
      client_updated_at TEXT NOT NULL,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error TEXT,
      sync_error_code TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (school_id, month, staff_member_id)
    )
  ''',
);

/// `payroll_gestures` — les gestes du circuit (`SUBMIT`, `RETURN`,
/// `VALIDATE`, `REOPEN`), un par ligne, jamais fusionnés. `id` = le
/// `gestureId`, clé d'idempotence et id de l'entrée d'outbox. Ceux du serveur
/// descendent avec la paie (`SYNCED`) ; ceux de la tablette y attendent leur
/// accusé.
///
/// - `expected` : l'empreinte vue à la confirmation (JSON), pour `SUBMIT` et
///   `VALIDATE` ;
/// - `server_state` : les chiffres du serveur rendus par un refus
///   `PAYROLL_STALE` (JSON), lus par l'écran de confrontation.
const TableSchema payrollGesturesTable = TableSchema(
  name: 'payroll_gestures',
  createTableSql: '''
    CREATE TABLE payroll_gestures (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      month TEXT NOT NULL,
      kind TEXT NOT NULL,
      reason TEXT,
      expected TEXT,
      recorded_at TEXT NOT NULL,
      author_name TEXT,
      server_state TEXT,
      sync_status TEXT NOT NULL DEFAULT 'PENDING_SYNC',
      sync_error TEXT,
      sync_error_code TEXT,
      created_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_payroll_gestures_month '
        'ON payroll_gestures(school_id, month)',
  ],
);

/// `payroll_lines` — les lignes **figées** d'une paie validée, telles que le
/// serveur les a calculées. `line` porte la ligne entière (JSON) ; les
/// colonnes à côté servent aux requêtes. Vidées quand la paie est rouverte.
const TableSchema payrollLinesTable = TableSchema(
  name: 'payroll_lines',
  createTableSql: '''
    CREATE TABLE payroll_lines (
      school_id TEXT NOT NULL,
      month TEXT NOT NULL,
      staff_member_id TEXT NOT NULL,
      currency TEXT NOT NULL,
      net_in_cents INTEGER NOT NULL,
      line TEXT NOT NULL,
      updated_at INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (school_id, month, staff_member_id)
    )
  ''',
);

/// `staff_attendance_summaries` — le résumé d'un mois **clos** du Pointage,
/// servi sous `hr.pay.read` : ce que la paie consomme, sans le registre. Un
/// mois clos ne se rouvre pas : une ligne est immuable. `agents` (JSON) liste
/// les minutes réellement pointées et les compteurs ; un agent absent vaut
/// zéro partout.
const TableSchema staffAttendanceSummariesTable = TableSchema(
  name: 'staff_attendance_summaries',
  createTableSql: '''
    CREATE TABLE staff_attendance_summaries (
      school_id TEXT NOT NULL,
      month TEXT NOT NULL,
      closed_at TEXT,
      agents TEXT NOT NULL,
      server_updated_at TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (school_id, month)
    )
  ''',
);

/// `salary_advances` — une avance sur salaire, un fait. Son annulation est un
/// geste à part (`cancellation_*`), jamais une suppression.
///
/// `deducted_in_cents` / `balance_in_cents` : ce que le serveur a figé, lus
/// par le seul registre des avances — le calcul lit les lignes de paie.
const TableSchema salaryAdvancesTable = TableSchema(
  name: 'salary_advances',
  createTableSql: '''
    CREATE TABLE salary_advances (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      staff_member_id TEXT NOT NULL,
      amount_in_cents INTEGER NOT NULL,
      currency TEXT NOT NULL,
      installments INTEGER NOT NULL,
      first_month TEXT NOT NULL,
      reason TEXT NOT NULL,
      reason_detail TEXT,
      mode TEXT NOT NULL,
      granted_on TEXT NOT NULL,
      client_recorded_at TEXT NOT NULL,
      deducted_in_cents INTEGER NOT NULL DEFAULT 0,
      balance_in_cents INTEGER,
      cancelled_at TEXT,
      cancellation_id TEXT,
      cancellation_reason TEXT,
      cancellation_status TEXT,
      cancellation_error TEXT,
      server_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error TEXT,
      sync_error_code TEXT,
      created_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_salary_advances_member '
        'ON salary_advances(school_id, staff_member_id)',
    'CREATE INDEX idx_salary_advances_cancellation '
        'ON salary_advances(cancellation_id)',
  ],
);

/// `payroll_disbursements` — un salaire versé, un fait. Le montant est le net
/// figé, jamais une saisie. `validation_gesture_id` nomme la validation sous
/// laquelle l'argent est sorti.
///
/// Un versement refusé n'est **jamais effacé** : l'argent est parti. Il reste
/// en `SYNC_ERROR` avec son code, et l'écran le liste « à régulariser ».
const TableSchema payrollDisbursementsTable = TableSchema(
  name: 'payroll_disbursements',
  createTableSql: '''
    CREATE TABLE payroll_disbursements (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      month TEXT NOT NULL,
      staff_member_id TEXT NOT NULL,
      validation_gesture_id TEXT NOT NULL,
      amount_in_cents INTEGER NOT NULL,
      currency TEXT NOT NULL,
      mode TEXT NOT NULL,
      operator TEXT,
      payout_phone TEXT,
      reference TEXT,
      bank_name TEXT,
      bank_account TEXT,
      signed_register INTEGER NOT NULL DEFAULT 0,
      paid_at TEXT NOT NULL,
      author_name TEXT,
      cancelled_at TEXT,
      cancellation_id TEXT,
      cancellation_reason TEXT,
      cancellation_status TEXT,
      cancellation_error TEXT,
      server_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error TEXT,
      sync_error_code TEXT,
      created_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_payroll_disbursements_month '
        'ON payroll_disbursements(school_id, month)',
    'CREATE INDEX idx_payroll_disbursements_cancellation '
        'ON payroll_disbursements(cancellation_id)',
  ],
);

/// `payroll_share_traces` — « bulletin ouvert dans WhatsApp le … », « PDF
/// téléchargé le … ». **Jamais poussée** : ouvrir WhatsApp n'est pas envoyer,
/// et une trace partagée laisserait croire que l'agent l'a reçu.
const TableSchema payrollShareTracesTable = TableSchema(
  name: 'payroll_share_traces',
  createTableSql: '''
    CREATE TABLE payroll_share_traces (
      school_id TEXT NOT NULL,
      month TEXT NOT NULL,
      staff_member_id TEXT NOT NULL,
      channel TEXT NOT NULL,
      shared_at TEXT NOT NULL,
      PRIMARY KEY (school_id, month, staff_member_id, channel)
    )
  ''',
);

const List<TableSchema> payrollTables = [
  refPayrollSettingsTable,
  staffPayProfilesTable,
  payrollsTable,
  payrollVariablesTable,
  payrollGesturesTable,
  payrollLinesTable,
  staffAttendanceSummariesTable,
  salaryAdvancesTable,
  payrollDisbursementsTable,
  payrollShareTracesTable,
];
