/// Tables du fichier du personnel (module Ressources humaines, sous-module A).
///
/// Trois flux, trois droits, trois tables — et c'est la frontière de sécurité,
/// pas une commodité :
/// - `staff_members` (flux `hr.staff-members`, `hr.staff.read`) : la fiche et la
///   frise des contrats **sans montants** ;
/// - `staff_contracts` (flux `hr.staff-contracts`, `hr.pay.read`) : les périodes
///   **avec** leurs montants. Une tablette sans le droit n'y a aucune ligne ;
/// - `staff_documents` (flux `hr.staff-documents`, `hr.document.read`) : les
///   **métadonnées** des pièces ; les octets vivent chiffrés hors de la base.
///
/// Rien ici ne référence un autre module : un agent n'est ni un élève ni une
/// écriture de caisse.
library;

import 'package:school_app_flutter/core/database/table_schema.dart';

/// `ref_staff_document_types` — les pièces du dossier et les contrats qui les
/// exigent (section `staffDocumentTypes` du socle), remplacées d'un bloc par
/// école. `required_for` : les `StaffContractKind` séparés par des virgules.
const TableSchema refStaffDocumentTypesTable = TableSchema(
  name: 'ref_staff_document_types',
  createTableSql: '''
    CREATE TABLE ref_staff_document_types (
      school_id TEXT NOT NULL,
      code TEXT NOT NULL,
      label TEXT NOT NULL,
      always_required INTEGER NOT NULL DEFAULT 0,
      required_for TEXT NOT NULL DEFAULT '',
      sort_order INTEGER NOT NULL DEFAULT 0,
      synced_at INTEGER NOT NULL DEFAULT 0,
      PRIMARY KEY (school_id, code)
    )
  ''',
);

/// `staff_members` — la fiche d'un agent.
///
/// - `staff_number` : `CF-AG-0048`, `NULL` tant que le serveur ne l'a pas
///   attribué (« en attente »). Jamais construit ni découpé par le poste.
/// - `branches`, `diplomas`, `contracts` : JSON. Les deux premiers sont saisis
///   et remplacés d'un bloc ; `contracts` est la frise **sans montants**,
///   calculée par le serveur et jamais écrite par le poste.
/// - `client_updated_at` : horloge d'arbitrage (ISO-8601 UTC), dernier écrit
///   gagne. `NULL` pour un agent repris d'avant le fichier.
/// - Jours (`birth_date`, `entry_date`) en `YYYY-MM-DD`, sans fuseau.
const TableSchema staffMembersTable = TableSchema(
  name: 'staff_members',
  createTableSql: '''
    CREATE TABLE staff_members (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      staff_number TEXT,
      last_name TEXT NOT NULL,
      middle_name TEXT,
      first_name TEXT NOT NULL,
      sex TEXT,
      birth_date TEXT,
      phone_number TEXT,
      email TEXT,
      city TEXT,
      district TEXT,
      municipality TEXT,
      neighborhood TEXT,
      address TEXT,
      category TEXT NOT NULL,
      job_title TEXT,
      entry_date TEXT,
      branches TEXT NOT NULL DEFAULT '[]',
      diplomas TEXT NOT NULL DEFAULT '[]',
      contracts TEXT NOT NULL DEFAULT '[]',
      client_updated_at TEXT,
      version INTEGER,
      server_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error TEXT,
      sync_error_code TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_staff_members_school '
        'ON staff_members(school_id, last_name)',
    'CREATE INDEX idx_staff_members_sync ON staff_members(sync_status)',
  ],
);

/// `staff_contracts` — une période de contrat **avec** ses montants, sous
/// `hr.pay.read` seulement. Fait figé : jamais réécrit, une période fausse est
/// marquée corrigée (`corrected_at`) et reste pour l'historique.
///
/// Montants en centimes dans leur devise, jamais convertis.
///
/// `correction_pending_id` est **local** : l'identifiant d'une correction
/// écrite sur le poste et pas encore accusée. `corrected_at` appartient au
/// serveur, qui le pose à l'accusé — le poste ne l'écrit jamais.
const TableSchema staffContractsTable = TableSchema(
  name: 'staff_contracts',
  createTableSql: '''
    CREATE TABLE staff_contracts (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      staff_member_id TEXT NOT NULL,
      kind TEXT NOT NULL,
      pay_mode TEXT,
      effective_from TEXT NOT NULL,
      ends_on TEXT,
      amount_in_cents INTEGER,
      currency TEXT,
      secope_number TEXT,
      bonus_in_cents INTEGER,
      bonus_currency TEXT,
      recorded_at TEXT NOT NULL,
      corrected_at TEXT,
      corrected_by_name TEXT,
      replaced_by TEXT,
      correction_reason TEXT,
      version INTEGER,
      server_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error TEXT,
      sync_error_code TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0,
      correction_pending_id TEXT
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_staff_contracts_member '
        'ON staff_contracts(staff_member_id, effective_from)',
  ],
);

/// `staff_documents` — les métadonnées d'une pièce versée. Fait figé : la
/// pièce courante d'un code est la plus récente (`captured_at`) ; « remplacer »
/// en verse une nouvelle. Les octets ne sont jamais ici : ils vivent chiffrés
/// dans le magasin du module, sous l'`id` de la pièce.
const TableSchema staffDocumentsTable = TableSchema(
  name: 'staff_documents',
  createTableSql: '''
    CREATE TABLE staff_documents (
      id TEXT PRIMARY KEY,
      school_id TEXT NOT NULL,
      staff_member_id TEXT NOT NULL,
      code TEXT NOT NULL,
      source TEXT NOT NULL,
      captured_at TEXT NOT NULL,
      file_name TEXT,
      mime_type TEXT NOT NULL,
      size_bytes INTEGER NOT NULL,
      sha256 TEXT NOT NULL,
      version INTEGER,
      server_updated_at TEXT,
      sync_status TEXT NOT NULL DEFAULT 'SYNCED',
      sync_error TEXT,
      sync_error_code TEXT,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: [
    'CREATE INDEX idx_staff_documents_member '
        'ON staff_documents(staff_member_id, code)',
  ],
);

const List<TableSchema> staffOfflineTables = [
  refStaffDocumentTypesTable,
  staffMembersTable,
  staffContractsTable,
  staffDocumentsTable,
];
