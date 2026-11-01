import 'package:school_app_flutter/core/money/currency_code.dart';
import 'package:school_app_flutter/features/payroll/domain/entities/payroll_deduction.dart';

/// Une rubrique que le moteur retient pour une ligne.
class PayrollResolvedDeduction {
  final PayrollDeductionType type;
  final int amountInCents;

  /// Le montant vient du catalogue, sans saisie : il ne peut pas être dans une
  /// autre devise que sa ligne, donc jamais bloquer le circuit.
  final bool fromDefault;

  const PayrollResolvedDeduction({
    required this.type,
    required this.amountInCents,
    required this.fromDefault,
  });
}

/// Ce qu'un agent doit à chaque rubrique ce mois-ci, à partir du catalogue et
/// de ses saisies : fonction pure, à l'identique de la résolution du serveur.
///
/// ```text
/// saisie présente         son montant, s'il est > 0 et dans la devise de la
///                         ligne ; sinon rien — elle écarte toujours le défaut
/// aucune saisie           le défaut, si la rubrique est active, dans la
///                         devise de la ligne et connue du serveur ou encore
///                         en file ; sinon rien
/// ```
/// Rendu dans l'ordre du moteur : `sortOrder`, puis identifiant en texte. Une
/// saisie sur une rubrique absente du catalogue ne compte pas ici :
/// `PayrollDeductionIssues` la signale.
abstract final class PayrollDeductionResolver {
  static List<PayrollResolvedDeduction> resolve(
    List<PayrollDeductionType> types,
    List<PayrollDeductionEntry> entries,
    String currency,
  ) {
    final line = CurrencyCode.normalize(currency);
    final entryOf = {
      for (final entry in entries) entry.deductionTypeId.toLowerCase(): entry,
    };
    final resolved = <PayrollResolvedDeduction>[];
    for (final type in types) {
      final entry = entryOf[type.id.toLowerCase()];
      if (entry != null) {
        if (entry.amountInCents > 0 &&
            CurrencyCode.normalize(entry.currency) == line) {
          resolved.add(
            PayrollResolvedDeduction(
              type: type,
              amountInCents: entry.amountInCents,
              fromDefault: false,
            ),
          );
        }
      } else if (!type.archived &&
          type.defaultCounts &&
          type.appliesTo(line) &&
          type.defaultAmountInCents > 0) {
        resolved.add(
          PayrollResolvedDeduction(
            type: type,
            amountInCents: type.defaultAmountInCents,
            fromDefault: true,
          ),
        );
      }
    }
    return resolved..sort((a, b) {
      final byOrder = a.type.sortOrder.compareTo(b.type.sortOrder);
      return byOrder != 0
          ? byOrder
          : a.type.id.toLowerCase().compareTo(b.type.id.toLowerCase());
    });
  }
}
