part of 'tenant_migrations.dart';

/// v68 — la Paie v2 (doc tablette « Paie v2 — adaptation tablette »,
/// 2026-10-24).
///
/// Un seul palier pour toute la livraison, comme à la v66 : chaque lot y
/// ajoute ses colonnes et ses tables, toutes gardées. Additif — une école qui
/// ne règle rien est payée comme en v1.
///
/// - `ref_payroll_settings` : diviseur de jours (26) et retenue d'absence
///   (coupée). Le forfait IPR et la CNSS voyagent dans `by_currency`.
/// - `staff_members.grade` : le grade de l'agent, lu par l'état de paie. Pas
///   de re-pull : le champ naît vide au serveur, il ne descend qu'une fois
///   saisi, donc avec une ligne modifiée.
/// - `payroll_variables` : jours prestés (NJP), prise en charge (PC/E),
///   montant fixe versé et son motif.
/// - `payroll_payout_policies` : le taux de versement du mois.
/// - `payroll_arrears_priorities` : le drapeau « priorité » des arriérés.
/// - `expenses.staff_advance` : le bloc R.H. d'une avance au personnel
///   déposée comme dépense (B5). Pas de re-pull : le type naît avec Q4.
Future<void> _payrollV2(DatabaseExecutor db) async {
  await _addColumns(db, 'ref_payroll_settings', const {
    'work_days_divisor': 'INTEGER NOT NULL DEFAULT 26',
    'absence_deduction_enabled': 'INTEGER NOT NULL DEFAULT 0',
  });
  await _addColumns(db, 'staff_members', const {'grade': 'TEXT'});
  await _addColumns(db, 'payroll_variables', const {
    'worked_days': 'INTEGER',
    'childcare_in_cents': 'INTEGER',
    'fixed_payout_in_cents': 'INTEGER',
    'fixed_payout_reason': 'TEXT',
  });
  await _addColumns(db, 'expenses', const {'staff_advance': 'TEXT'});
  await _createTables(db, const [
    payrollPayoutPoliciesTable,
    payrollArrearsPrioritiesTable,
  ]);
}
