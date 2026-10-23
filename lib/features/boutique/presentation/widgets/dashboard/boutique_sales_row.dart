import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_sale_row.dart';
import 'package:school_app_flutter/features/boutique/presentation/helpers/boutique_sale_time.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une vente en ligne de table : Date · Reçu · Élève(s) · Montant.
///
/// **Les élèves, pas le payeur** : c'est ce que la direction cherche — « qui
/// a eu quoi ». Le payeur ne s'écrit que pour une vente sans élève, marqué
/// comme tel ; sans payeur non plus, la vente se dit anonyme.
abstract final class BoutiqueSalesRow {
  static DataTableRowSpec of(
    BoutiqueSaleRow sale,
    AppLocalizations l10n, {
    required void Function(BoutiqueSaleRow sale) onOpen,
    DateTime? now,
  }) {
    final (students, classes) = _whoOf(sale, l10n);
    void open() => onOpen(sale);

    return DataTableRowSpec(
      id: sale.saleId,
      displayName: students,
      // La ligne EST le geste, l'œil le redit — comme à la caisse.
      onTap: open,
      trailing: DataTableTrailingSpec(
        type: DataTableTrailingType.eye,
        tooltip: l10n.boutiqueLatestSalesOpen,
        onTap: open,
      ),
      cells: [
        DataTableCellSpec(
          text: BoutiqueSaleTime.of(sale.soldAt, now ?? DateTime.now()),
          variant: DataTableCellTextVariant.mono,
        ),
        DataTableCellSpec(
          text: sale.receiptNumber ?? l10n.boutiqueSalesReceiptPending,
          variant: DataTableCellTextVariant.mono,
        ),
        DataTableCellSpec(
          text: students,
          variant: DataTableCellTextVariant.strong,
          secondaryText: classes,
        ),
        DataTableCellSpec(
          // Exact, jamais arrondi, deux devises côte à côte — et le total du
          // reçu entier, même sous un filtre : la ligne recoupe le papier.
          text: sale.amounts.entries.map(MoneyFormat.format).join(' · '),
          variant: DataTableCellTextVariant.strong,
          secondaryText: l10n.boutiqueHistoryArticleCount(sale.articleCount),
        ),
      ],
    );
  }

  /// Les élèves, et leurs classes en seconde ligne — chacune une fois.
  static (String, String?) _whoOf(BoutiqueSaleRow sale, AppLocalizations l10n) {
    if (sale.beneficiaries.isEmpty) {
      final payer = sale.payerName;
      return (
        payer == null
            ? l10n.boutiqueSalesAnonymous
            : l10n.boutiqueSalesPayer(payer),
        null,
      );
    }
    final names = [
      for (final student in sale.beneficiaries)
        student.fullName ?? l10n.boutiqueSalesStudentUnknown,
    ];
    final classes = <String>{
      for (final student in sale.beneficiaries)
        student.classLabel ?? l10n.boutiqueSalesNoClass,
    };
    return (names.join(', '), classes.join(' · '));
  }
}
