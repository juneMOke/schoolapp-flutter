import 'package:school_app_flutter/core/export/csv_writer.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Helper d'export CSV pour les relevés de la facturation (spec §21).
///
/// Le **format** (BOM UTF-8, séparateur `;`, CRLF, cellules guillemetées) vit
/// désormais dans [CsvWriter], au socle : il n'avait rien de financier, et le
/// tableau de bord des inscriptions exporte au même format. Ce helper ne garde
/// que ce qui est propre à la facturation — quelles colonnes, quel libellé de
/// repli, quel nom de fichier.
///
/// TODO(backend) : la spec §21 prévoit des colonnes supplémentaires
/// (Date, Payeur, Lien, Moyen, Encaissé par, Reçu). Ces colonnes nécessitent
/// des champs aujourd'hui absents des modèles `Payment` / `PaymentAllocation`
/// (`PaymentAllocation` n'expose que id, paymentId, studentChargeId, feeCode,
/// studentChargeLabel, amountInCents, currency). Tant que le backend ne
/// renvoie pas ces données, l'export se limite aux colonnes réellement
/// disponibles : Frais + Montant imputé.
class FinanceCsvExportHelper {
  const FinanceCsvExportHelper._();

  /// Construit le CSV du relevé d'un frais à partir de ses allocations.
  ///
  /// En-têtes : [l10n.facturationCsvHeaderFee, l10n.facturationCsvHeaderImputedAmount].
  /// Une ligne par allocation : libellé du frais + montant imputé (en unités,
  /// soit `amountInCents / 100`, formaté simplement pour le CSV).
  static String buildChargeStatementCsv({
    required AppLocalizations l10n,
    required List<PaymentAllocation> allocations,
    required String currency,
  }) {
    return CsvWriter.document([
      [l10n.facturationCsvHeaderFee, l10n.facturationCsvHeaderImputedAmount],
      for (final allocation in allocations)
        [
          allocation.studentChargeLabel.trim().isNotEmpty
              ? allocation.studentChargeLabel
              : allocation.feeCode,
          _formatAmount(allocation.amountInCents),
        ],
    ]);
  }

  /// Construit un nom de fichier du type `paiements-{frais}-{nom}-{prenom}.csv`.
  static String buildStatementFileName({
    required String chargeLabel,
    required String firstName,
    required String lastName,
  }) => CsvWriter.fileName(['paiements', chargeLabel, lastName, firstName]);

  /// Montant lisible pour le CSV : conversion cents -> unités, sans espace
  /// insécable ni symbole, avec 2 décimales (ex. `1500` -> `15.00`).
  static String _formatAmount(int amountInCents) =>
      (amountInCents / 100).toStringAsFixed(2);
}
