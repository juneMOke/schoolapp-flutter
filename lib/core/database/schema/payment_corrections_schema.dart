import 'package:school_app_flutter/core/database/table_schema.dart';

/// `payment_corrections` — un geste « Annuler » ou « Corriger » sur un
/// versement (v54, plan « Correction d'un versement hors ligne », lot T1).
///
/// ⚠️ **L'annulation locale vit ICI, jamais dans `payments.cancelled_at`.** Le
/// pull n'efface jamais cette colonne (« une extourne ne se défait pas ») : un
/// refus du serveur ne pourrait plus rétablir l'origine. `cancelled_at` reste
/// réservé au serveur ; les lectures de solde retirent l'origine tant qu'une
/// correction la vise dans un état qui l'écarte (cf. `PaymentInForceSql`).
///
/// - `payment_id` : le versement visé (l'origine) ; `student_id` est le sien.
/// - `replacement_payment_id` : le remplaçant, `NULL` pour une annulation
///   seule. Il vit dans `payments` comme tout versement, mais voyage DANS la
///   correction : jamais d'entrée d'outbox `PAYMENT` à lui.
/// - `reason_code` : liste fermée, filtrée selon le geste ; `reason` est la
///   précision libre, requise pour `OTHER`.
/// - `cash_moved` : le caissier a confirmé que de l'argent a vraiment changé
///   de main (D8), pour le futur arrêté de caisse.
/// - `client_cancelled_at` : ISO-8601 UTC, l'heure du geste, pour l'audit.
/// - `status` : `PaymentCorrectionStatus`. `sync_error` / `sync_error_code` et
///   `server_detail` (JSON brut de la réponse de refus) disent pourquoi une
///   correction a été refusée.
const TableSchema paymentCorrectionsTable = TableSchema(
  name: 'payment_corrections',
  createTableSql: '''
    CREATE TABLE payment_corrections (
      id TEXT PRIMARY KEY,
      payment_id TEXT NOT NULL,
      student_id TEXT NOT NULL,
      replacement_payment_id TEXT,
      reason_code TEXT NOT NULL,
      reason TEXT,
      cash_moved INTEGER NOT NULL DEFAULT 0,
      client_cancelled_at TEXT NOT NULL,
      author_id TEXT,
      status TEXT NOT NULL DEFAULT 'PENDING',
      sync_error TEXT,
      sync_error_code TEXT,
      server_detail TEXT,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL DEFAULT 0
    )
  ''',
  createIndexSql: kPaymentCorrectionsIndexSql,
);

/// Partagés par le schéma vivant et le palier v54 : les deux chemins doivent
/// aboutir aux mêmes index. Écrits SANS `IF NOT EXISTS` : l'escalier hérité
/// l'ajoute lui-même aux index du schéma vivant, et le palier v54 aussi.
const List<String> kPaymentCorrectionsIndexSql = [
  'CREATE INDEX idx_payment_corrections_payment '
      'ON payment_corrections(payment_id)',
  'CREATE INDEX idx_payment_corrections_replacement '
      'ON payment_corrections(replacement_payment_id)',
  'CREATE INDEX idx_payment_corrections_student '
      'ON payment_corrections(student_id)',
];

/// Index de `payments.replaces_payment_id` : l'origine retrouve son
/// remplaçant (« Remplacé par … ») sans balayer la table.
const String kPaymentsReplacesIndexSql =
    'CREATE INDEX idx_payments_replaces '
    'ON payments(replaces_payment_id)';
