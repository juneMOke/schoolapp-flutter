import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/domain/repositories/finance_repository.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_receipts_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/till_currency_order.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_chart_card.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **La preuve** — une ligne d'encaissement par ligne de table.
///
/// ⚠️ **Pas un reçu par ligne.** Un versement qui a pris des francs *et* des
/// dollars apparaît **deux fois sous le même numéro**, et ce n'est pas un
/// doublon : c'est la conséquence directe de « l'unité est la ligne de tender »,
/// et c'est ce que le caissier retrouve dans son tiroir.
///
/// C'est la ligne qui explique les écarts au contrôle de caisse — d'où la
/// seconde ligne ambre quand un frais fixé dans une devise a été réglé dans
/// l'autre.
class FinanceTillReceiptsSection extends StatelessWidget {
  /// Le total de la caisse décrite, déjà formaté — il complète le sous-titre.
  /// Lu sur les agrégats, jamais recomposé depuis les lignes de la page : la
  /// page n'en montre que huit.
  final String tillTotal;

  const FinanceTillReceiptsSection({super.key, required this.tillTotal});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<FinanceTillReceiptsBloc, FinanceTillReceiptsState>(
      builder: (context, state) {
        final currency = state.currency;
        if (currency == null) return const SizedBox.shrink();

        return FinanceStatsChartCard(
          title: l10n.financeTillReceiptsHeading(
            tillCurrencyName(currency, l10n),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Subtitle(state: state, tillTotal: tillTotal, l10n: l10n),
              const SizedBox(height: AppDimensions.spacingM),
              _body(context, l10n, state, currency),
            ],
          ),
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    FinanceTillReceiptsState state,
    String currency,
  ) {
    // ⚠️ **L'erreur de CETTE table n'est pas l'erreur de l'écran.**
    //
    // Le cas qui l'impose : un porteur du seul pilotage reçoit 200 sur les
    // agrégats et 403 ici. Le taux, la fenêtre, les caisses, le graphique et
    // les ventilations viennent d'un appel qui a réussi et restent donc
    // affichés ; seule cette carte dit ce qui lui manque.
    if (state.status == FinanceTillReceiptsStatus.error) {
      final forbidden = state.failure is UnauthorizedFailure;
      return _InlineMessage(
        icon: forbidden ? Icons.gpp_bad_rounded : Icons.error_outline_rounded,
        text: forbidden
            ? l10n.financeTillReceiptsForbidden
            : l10n.financeTillReceiptsError,
      );
    }

    return DataTableView(
      rows: [
        for (final receipt in state.receipts) _rowOf(context, l10n, receipt),
      ],
      config: DataTableViewConfig(
        isLoading: state.status == FinanceTillReceiptsStatus.loading,
        loadingLabel: l10n.financeTillReceiptsLoading,
        emptyLabel: l10n.financeTillReceiptsEmpty,
        semanticsLabel: l10n.financeTillReceiptsHeading(
          tillCurrencyName(currency, l10n),
        ),
        density: DataTableDensity.compact,
        columns: [
          DataTableColumnDef(
            label: l10n.financeTillReceiptsColumnDate,
            flex: 10,
          ),
          DataTableColumnDef(
            label: l10n.financeTillReceiptsColumnReceipt,
            flex: 16,
          ),
          DataTableColumnDef(
            label: l10n.financeTillReceiptsColumnStudent,
            flex: 24,
          ),
          DataTableColumnDef(
            label: l10n.financeTillReceiptsColumnSource,
            flex: 12,
          ),
          DataTableColumnDef(
            label: l10n.financeTillReceiptsColumnAmount,
            flex: 16,
          ),
        ],
        footer: DataTableFooterConfig(
          label: l10n.financeTillReceiptsCount(state.totalElements),
          total: state.totalElements,
          unit: l10n.financeTillReceiptsUnit,
          pagination: !state.hasMultiplePages
              ? null
              : DataTablePaginationConfig(
                  // Le serveur compte les pages à partir de 0, la barre du
                  // socle à partir de 1.
                  currentPage: state.page + 1,
                  totalPages: state.totalPages,
                  pageSize: TillReceiptsQuery.defaultPageSize,
                  isLoading: state.status == FinanceTillReceiptsStatus.loading,
                  onPrevious: () => context.read<FinanceTillReceiptsBloc>().add(
                    FinanceTillReceiptsPageChanged(state.page - 1),
                  ),
                  onNext: () => context.read<FinanceTillReceiptsBloc>().add(
                    FinanceTillReceiptsPageChanged(state.page + 1),
                  ),
                ),
        ),
      ),
    );
  }

  DataTableRowSpec _rowOf(
    BuildContext context,
    AppLocalizations l10n,
    TillReceipt receipt,
  ) {
    final materialL10n = MaterialLocalizations.of(context);

    return DataTableRowSpec(
      // La clé porte aussi la devise : un panier mixte rend **deux lignes** sous
      // le même `paymentId`, et une clé qui l'ignorerait en ferait un doublon.
      id: '${receipt.paymentId}#${receipt.currency}',
      displayName: receipt.studentName ?? l10n.financeTillReceiptsNoStudent,
      // Le reçu s'ouvre depuis Facturation, jamais depuis le tableau de bord :
      // pas de clic promis ici.
      cells: [
        DataTableCellSpec(
          text: materialL10n.formatCompactDate(receipt.paidAt.toLocal()),
          variant: DataTableCellTextVariant.mono,
        ),
        DataTableCellSpec(
          // Lu tel quel — jamais recomposé, et le préfixe n'est pas un code
          // d'école. Absent ⇒ tiret : un versement antérieur à l'imprimerie
          // n'a pas de pièce, et l'identifiant technique ne la remplace pas.
          text: receipt.receiptNumber ?? l10n.financeTillReceiptsNoNumber,
          variant: DataTableCellTextVariant.mono,
        ),
        DataTableCellSpec(
          text: receipt.studentName ?? l10n.financeTillReceiptsNoStudent,
          variant: DataTableCellTextVariant.strong,
          secondaryText: _studentLine(receipt, l10n),
        ),
        DataTableCellSpec(
          child: _SourcePill(source: receipt.source, l10n: l10n),
        ),
        DataTableCellSpec(
          text: MoneyFormat.format(
            Money.parse(receipt.amount, receipt.currency),
          ),
          variant: DataTableCellTextVariant.strong,
          // La mention du croisement est **du texte**, pas seulement une
          // teinte ambre : la doctrine interdit qu'une conversion se signale
          // par la seule couleur.
          secondaryText: _crossingLine(receipt, l10n),
        ),
      ],
    );
  }

  /// « classe · encaissé par caissier » — chaque moitié tombe si elle manque,
  /// plutôt que d'écrire un tiret au milieu d'une phrase.
  static String? _studentLine(TillReceipt receipt, AppLocalizations l10n) {
    final parts = <String>[
      if (receipt.classroom != null) receipt.classroom!,
      if (receipt.collectedBy != null)
        l10n.financeTillReceiptsCollectedBy(receipt.collectedBy!),
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// « solde 115 000 FC · taux 2 850 » — rendue **seulement** si le croisement
  /// est complet. Le montant soldé est lu sur les imputations, jamais dérivé du
  /// taux : la division produirait un arrondi qui ne retombe pas sur ce que la
  /// créance a réellement perdu.
  static String? _crossingLine(TillReceipt receipt, AppLocalizations l10n) {
    if (!receipt.isCrossed) return null;
    return l10n.financeTillReceiptsCrossed(
      MoneyFormat.format(
        Money.parse(receipt.settledAmount!, receipt.settledCurrency!),
      ),
      _formatRate(receipt.rateMicros!),
    );
  }

  /// Le taux, rendu depuis les micro-unités sans décimale superflue : `2 850`
  /// et non `2 850,000000`.
  static String _formatRate(int rateMicros) {
    final units = rateMicros / ExchangeRate.scale;
    return units == units.roundToDouble()
        ? units.round().toString()
        : units.toString();
  }
}

/// D'où vient la ligne — **une pastille, pas un mot nu**.
///
/// La spec la dessine ainsi : `landmark` pour la facturation, `store` pour la
/// boutique, chacune sur son fond. L'icône **double** le libellé, elle ne le
/// remplace pas : une source portée par la seule teinte serait invisible à qui
/// ne distingue pas les deux.
class _SourcePill extends StatelessWidget {
  final String source;
  final AppLocalizations l10n;

  const _SourcePill({required this.source, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final isBoutique = source == 'BOUTIQUE';
    final label = isBoutique
        ? l10n.financeTillSourceBoutique
        : l10n.financeTillSourceFees;
    final accent = isBoutique ? AppColors.terreCuite : AppColors.bleuArdoise;
    final surface = isBoutique
        ? AppColors.terreCuiteSoft
        : AppColors.bleuArdoiseSoft;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            // `landmark` / `store` de la spec, dans leurs équivalents Material.
            isBoutique ? Icons.storefront_outlined : Icons.account_balance,
            size: 13,
            color: accent,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// « 17 reçus · 4 120 $ · 2 sans pièce scellée » — **trois chiffres de fenêtre**.
///
/// Les trois portent sur la même chose, et c'est ce qui les rend comparables.
/// Le compte des rattrapages vient du serveur (`withoutReceiptNumber`) et non
/// des lignes affichées : compté sur la page, il changerait à chaque tour de
/// pagination sous un total immobile.
class _Subtitle extends StatelessWidget {
  final FinanceTillReceiptsState state;
  final String tillTotal;
  final AppLocalizations l10n;

  const _Subtitle({
    required this.state,
    required this.tillTotal,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      l10n.financeTillReceiptsCount(state.totalElements),
      tillTotal,
      // N'apparaît qu'avec des rattrapages à annoncer : sur une fenêtre où
      // toutes les pièces existent, la mention n'aurait rien à expliquer.
      if (state.hasUnsealedReceipts)
        l10n.financeTillReceiptsUnsealed(state.withoutReceiptNumber),
    ];

    return Text(
      parts.join(' · '),
      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
    );
  }
}

/// Ce qui remplace la table quand elle seule échoue.
class _InlineMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InlineMessage({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: text,
      child: ExcludeSemantics(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(AppDimensions.spacingM),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textMuted),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
