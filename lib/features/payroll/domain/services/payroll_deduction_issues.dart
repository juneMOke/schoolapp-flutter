import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_line.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_month_view.dart';

/// Ce que les saisies de rubriques d'un mois disent au circuit.
class PayrollDeductionIssues {
  /// Dans une autre devise que leur ligne : hors calcul, elles bloquent
  /// `SUBMIT` et `VALIDATE`, comme au serveur.
  final List<PayrollDeductionEntry> foreign;

  /// Sur une rubrique absente du catalogue local : la tablette ne peut pas
  /// calculer l'ordre du moteur, son empreinte serait fausse.
  final List<PayrollDeductionEntry> unknown;

  /// Refusées ou supprimées : le montant refusé ne compte pas, à lire par
  /// l'économe.
  final List<PayrollDeductionEntry> refused;

  /// Une écriture de rubrique refusée sur une rubrique que le serveur connaît :
  /// son défaut, sur la tablette, n'est peut-être plus le sien.
  final bool typeRefused;

  const PayrollDeductionIssues({
    this.foreign = const [],
    this.unknown = const [],
    this.refused = const [],
    this.typeRefused = false,
  });

  static const PayrollDeductionIssues none = PayrollDeductionIssues();

  /// Ce qui empêche de soumettre ou de valider ; `null` : rien.
  PayrollBlocker? get blocker => foreign.isNotEmpty
      ? PayrollBlocker.deductionCurrency
      : unknown.isNotEmpty
      ? PayrollBlocker.deductionTypeUnknown
      : typeRefused
      ? PayrollBlocker.deductionTypeRefused
      : null;

  static PayrollDeductionIssues of({
    required Map<String, List<PayrollDeductionEntry>> entries,
    required List<PayrollDeductionType> types,
    required List<PayrollLine> lines,
  }) {
    final known = {for (final type in types) type.id.toLowerCase()};
    final currencies = {
      for (final line in lines)
        line.staffMemberId: CurrencyCode.normalize(line.currency),
    };
    final foreign = <PayrollDeductionEntry>[];
    final unknown = <PayrollDeductionEntry>[];
    final refused = <PayrollDeductionEntry>[];
    for (final list in entries.values) {
      for (final entry in list) {
        if (entry.syncState == RecordSyncState.failed) refused.add(entry);
        final counted = entry.counted;
        if (counted == null || counted.amountInCents <= 0) continue;
        if (!known.contains(counted.deductionTypeId.toLowerCase())) {
          unknown.add(counted);
        } else if (currencies[counted.staffMemberId] case final currency?
            when currency != CurrencyCode.normalize(counted.currency)) {
          foreign.add(counted);
        }
      }
    }
    return PayrollDeductionIssues(
      foreign: foreign,
      unknown: unknown,
      refused: refused,
      typeRefused: types.any((type) => type.refusedOnServer),
    );
  }
}
