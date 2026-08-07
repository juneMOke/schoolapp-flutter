import 'package:school_app_flutter/features/finance/offline/domain/entities/finance_offline_enums.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';

/// Exigibilité locale (FF-Lot 5) — réplique PURE de `ExigibiliteService.statut()`
/// (sans I/O), pour l'affichage échu/à venir offline.
///
/// ```
/// reste = max(0, expected - paid)
/// si due_at == null || due_at > reference → A_VENIR
/// sinon si reste <= 0                      → ECHU_SOLDE
/// sinon si paid > 0                        → ECHU_PARTIEL
/// sinon                                    → ECHU_IMPAYE
/// ```
/// Le verdict autoritaire (arriéré exigible) reste serveur ; `reference` =
/// horloge locale.
ChargeExigibilite computeExigibilite({
  required int expectedInCents,
  required int paidInCents,
  DateTime? dueAt,
  required DateTime reference,
}) {
  final reste = expectedInCents - paidInCents;
  final resteClamped = reste < 0 ? 0 : reste;

  if (dueAt == null || dueAt.isAfter(reference)) {
    return ChargeExigibilite.aVenir;
  }
  if (resteClamped <= 0) return ChargeExigibilite.echuSolde;
  if (paidInCents > 0) return ChargeExigibilite.echuPartiel;
  return ChargeExigibilite.echuImpaye;
}

/// Exigibilité d'une créance locale, calculée sur le solde OPTIMISTE (affichage).
/// `dueAt` (yyyy-MM-dd) est parsé de façon tolérante (null si absent/invalide).
ChargeExigibilite exigibiliteForCharge(
  LocalStudentCharge charge, {
  required DateTime reference,
}) => computeExigibilite(
  expectedInCents: charge.expectedAmountInCents,
  paidInCents: charge.optimisticPaidInCents,
  dueAt: _parseDate(charge.dueAt),
  reference: reference,
);

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
