import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Helper d'export CSV pour les relevés de la facturation (spec §21).
///
/// Format conforme spec : BOM UTF-8 en tête, séparateur ';', fins de ligne
/// CRLF, et chaque cellule entourée de guillemets (les guillemets internes
/// étant doublés).
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

  /// BOM UTF-8 (U+FEFF) — assure une ouverture correcte dans Excel.
  static const String _bom = '\u{FEFF}';

  /// Séparateur de colonnes conforme spec §21.
  static const String _separator = ';';

  /// Fin de ligne CRLF conforme spec §21.
  static const String _lineEnding = '\r\n';

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
    final buffer = StringBuffer(_bom)
      ..write(
        _row([
          l10n.facturationCsvHeaderFee,
          l10n.facturationCsvHeaderImputedAmount,
        ]),
      );

    for (final allocation in allocations) {
      final label = allocation.studentChargeLabel.trim().isNotEmpty
          ? allocation.studentChargeLabel
          : allocation.feeCode;
      buffer.write(_row([label, _formatAmount(allocation.amountInCents)]));
    }

    return buffer.toString();
  }

  /// Construit un nom de fichier du type `paiements-{frais}-{nom}-{prenom}.csv`.
  static String buildStatementFileName({
    required String chargeLabel,
    required String firstName,
    required String lastName,
  }) {
    final parts = [
      'paiements',
      _slugify(chargeLabel),
      _slugify(lastName),
      _slugify(firstName),
    ].where((part) => part.isNotEmpty);
    return '${parts.join('-')}.csv';
  }

  /// Montant lisible pour le CSV : conversion cents -> unités, sans espace
  /// insécable ni symbole, avec 2 décimales (ex. `1500` -> `15.00`).
  static String _formatAmount(int amountInCents) =>
      (amountInCents / 100).toStringAsFixed(2);

  static String _row(List<String> values) =>
      values.map(_escapeCell).join(_separator) + _lineEnding;

  static String _escapeCell(String value) {
    final normalized = value.replaceAll('"', '""').trim();
    return '"$normalized"';
  }

  /// Slugifie une chaîne : minuscules, accents retirés, espaces et caractères
  /// non alphanumériques remplacés par des tirets (sans tirets en bordure).
  static String _slugify(String value) {
    final lowered = _removeDiacritics(value.trim().toLowerCase());
    final dashed = lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    return dashed.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  static String _removeDiacritics(String value) {
    const withDiacritics = 'àáâãäåçèéêëìíîïñòóôõöùúûüýÿ';
    const withoutDiacritics = 'aaaaaaceeeeiiiinooooouuuuyy';
    var result = value;
    for (var i = 0; i < withDiacritics.length; i++) {
      result = result.replaceAll(withDiacritics[i], withoutDiacritics[i]);
    }
    return result;
  }
}
