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
/// ## Toutes les caisses, contrairement à tout ce qui l'entoure
///
/// Les cartes au-dessus détaillent **une** caisse, celle du sélecteur ; cette
/// table-ci porte **tous les paiements de la fenêtre**, francs et dollars mêlés.
/// C'est ce qu'on vient y chercher : la liste de ce qui a été encaissé, pas la
/// liste d'un tiroir. Elle ne se rejoue donc pas quand on bascule de devise.
///
/// Le mélange se lit parce que **chaque montant porte son symbole** : il n'y a
/// pas de colonne où sommer deux unités, et le serveur pagine, compte et trie
/// la table entière — le filtre de devise vit dans la même requête que le
/// `LIMIT`, jamais après.
///
/// ⚠️ **Pas un reçu par ligne, et ça se voit maintenant.** Un versement qui a
/// pris des francs *et* des dollars apparaît **deux fois sous le même numéro** :
/// c'est la conséquence directe de « l'unité est la ligne de tender », et c'est
/// ce que le caissier retrouve dans son tiroir. Scopée sur une caisse, la table
/// n'en montrait qu'une des deux moitiés ; ici les deux se retrouvent voisines,
/// d'où la mention qui l'explique — sans elle, un lecteur y verrait un doublon.
///
/// C'est la ligne qui explique les écarts au contrôle de caisse — d'où la
/// seconde ligne ambre quand un frais fixé dans une devise a été réglé dans
/// l'autre.
class FinanceTillReceiptsSection extends StatelessWidget {
  /// Ce que la fenêtre a encaissé, **un montant par caisse**, déjà formaté.
  ///
  /// Lu sur les agrégats, jamais recomposé depuis les lignes de la page : la
  /// page n'en montre que huit. Ils complètent le sous-titre, et ne sont
  /// **jamais additionnés** — ce sont deux unités.
  final List<String> tillTotals;

  const FinanceTillReceiptsSection({super.key, required this.tillTotals});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<FinanceTillReceiptsBloc, FinanceTillReceiptsState>(
      builder: (context, state) {
        return FinanceStatsChartCard(
          title: l10n.financeTillReceiptsHeading,
          // Les versements de Facturation portent la même.
          icon: Icons.payments_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Subtitle(state: state, tillTotals: tillTotals, l10n: l10n),
              const SizedBox(height: AppDimensions.spacingM),
              _body(context, l10n, state),
              // ⚠️ Rendue **seulement quand la page en porte une**, comme la
              // note boutique : expliquer un doublon apparent qui n'est pas à
              // l'écran apprendrait au lecteur à s'en méfier partout.
              if (_hasSplitTender(state.receipts)) ...[
                const SizedBox(height: AppDimensions.spacingM),
                _SplitTenderNote(l10n: l10n),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Deux lignes de la page portent-elles le **même versement** ?
  ///
  /// Le cas du panier mixte : cent mille francs et dix dollars tendus au même
  /// guichet font deux lignes de tender sous un seul `paymentId`. Le tri du
  /// serveur est `(paidAt, id, tenderId)`, donc elles sont voisines — mais
  /// c'est la présence qui compte ici, pas l'adjacence.
  static bool _hasSplitTender(List<TillReceipt> receipts) {
    final seen = <String>{};
    for (final receipt in receipts) {
      if (!seen.add(receipt.paymentId)) return true;
    }
    return false;
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    FinanceTillReceiptsState state,
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
        semanticsLabel: l10n.financeTillReceiptsHeading,
        density: DataTableDensity.compact,
        // Les proportions de la spec — `1fr · 1,1fr · 2fr · 1fr · 1,2fr` —
        // portées en dixièmes.
        //
        // ⚠️ La spec leur donne aussi un **minimum** (`minmax(90, …)`,
        // `minmax(150, …)`…) que `DataTableColumnDef` ne sait pas exprimer : il
        // ne porte qu'un `flex`. Les rapports sont donc tenus, les planchers
        // non — à l'étroit, la colonne Élève rétrécira sous ses 150 dp.
        //
        // ## Écart assumé : la table COMPRIME, elle ne DÉFILE pas
        //
        // La spec veut, sur écran étroit, un « scroll horizontal » avec la
        // pagination conservée. La table du socle répartit ses colonnes en
        // `Expanded` : elle ne déborde jamais, elle serre. L'écran reste donc
        // correct sur l'appareil visé — une tablette autour de 1280 dp — mais
        // sur un téléphone les colonnes se tassent au lieu de défiler, et c'est
        // la ligne secondaire du croisement qui en souffre la première (d'où
        // son infobulle, qui la rend lisible malgré la coupe).
        //
        // **Ajourné, pas oublié.** Le défilement demande un minimum par colonne
        // dans `DataTableColumnDef` et un défilement horizontal dans la vue :
        // un chantier de socle sur un composant partagé par beaucoup d'écrans,
        // qui attend de savoir si quelqu'un ouvre vraiment cet écran sur un
        // téléphone. À ne pas bricoler ici — une table qui défilerait sur ce
        // seul écran divergerait de toutes les autres.
        columns: [
          DataTableColumnDef(
            label: l10n.financeTillReceiptsColumnDate,
            flex: 10,
          ),
          DataTableColumnDef(
            label: l10n.financeTillReceiptsColumnReceipt,
            flex: 11,
          ),
          DataTableColumnDef(
            label: l10n.financeTillReceiptsColumnStudent,
            flex: 20,
          ),
          DataTableColumnDef(
            label: l10n.financeTillReceiptsColumnSource,
            flex: 10,
          ),
          DataTableColumnDef(
            label: l10n.financeTillReceiptsColumnAmount,
            flex: 12,
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
          // ⚠️ **Et elle s'explique.** « solde 115 000 FC · taux 2 850,00 » dit
          // ce qui s'est passé sans dire pourquoi il y a deux devises sur une
          // ligne. L'explication est portée par une infobulle, qui est aussi
          // l'étiquette d'accessibilité — une mention qui ne s'obtiendrait qu'à
          // la souris n'existerait pas sur la tablette du caissier.
          //
          // Elle rattrape en outre la troncature : la ligne secondaire tient
          // sur une ligne, et dans une colonne étroite le taux disparaît le
          // premier.
          secondaryTooltip: _crossingExplanation(receipt, l10n),
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
      // ⚠️ **Deux décimales, contre la maquette qui écrit « taux 2 850 ».**
      // Un taux a une seule écriture dans cette application, parce qu'il
      // s'imprime aussi sur le ticket. Et ici la raison est plus forte encore :
      // ce taux-ci est celui **du reçu**, quand le bandeau porte celui **du
      // jour** — deux nombres différents par nature. Si leurs formats
      // différaient aussi, on ne pourrait plus savoir si un écart est dans la
      // valeur ou dans l'écriture.
      ExchangeRate.formatMicros(receipt.rateMicros!),
    );
  }

  /// « Frais fixé en dollars, réglé en francs » — le **pourquoi** des deux
  /// devises sur une même ligne.
  ///
  /// Les devises sont nommées et non symbolisées : l'infobulle est une phrase,
  /// et « Frais fixé en $ » se lit mal à voix haute.
  static String? _crossingExplanation(
    TillReceipt receipt,
    AppLocalizations l10n,
  ) {
    if (!receipt.isCrossed) return null;
    return l10n.financeTillReceiptsCrossedTooltip(
      tillCurrencyName(receipt.settledCurrency!, l10n),
      tillCurrencyName(receipt.currency, l10n),
    );
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

/// « 22 paiements · 4 120 $ et 1 350 000 FC · 2 sans pièce scellée » — **des
/// chiffres de fenêtre**.
///
/// Ils portent tous sur la même population, et c'est ce qui les rend
/// comparables. Le compte des rattrapages vient du serveur
/// (`withoutReceiptNumber`) et non des lignes affichées : compté sur la page, il
/// changerait à chaque tour de pagination sous un total immobile.
///
/// ⚠️ **Les montants sont ceux de la FACTURATION, pas les totaux de caisse.**
/// Un total de caisse inclut la boutique, que cette table ne montre pas — le
/// contrat le dit en toutes lettres : « le jour où la boutique tournera, le
/// total de caisse inclura des ventes que cette table ne montrera pas ». Poser
/// ce total-là à côté d'un compte de lignes qui l'exclut ferait diverger deux
/// chiffres voisins sans que rien ne le dise.
///
/// ⚠️ **Et ils ne s'additionnent jamais** : ce sont deux unités, jointes par
/// « et » et non par un « + ».
class _Subtitle extends StatelessWidget {
  final FinanceTillReceiptsState state;
  final List<String> tillTotals;
  final AppLocalizations l10n;

  const _Subtitle({
    required this.state,
    required this.tillTotals,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      l10n.financeTillReceiptsCount(state.totalElements),
      if (tillTotals.isNotEmpty)
        tillTotals.join(l10n.financeTillInsightAmountSeparator),
      // N'apparaît qu'avec des rattrapages à annoncer : sur une fenêtre où
      // toutes les pièces existent, la mention n'aurait rien à expliquer.
      if (state.hasUnsealedReceipts)
        l10n.financeTillReceiptsUnsealed(state.withoutReceiptNumber),
    ];

    return Text(
      parts.join(' · '),
      // Trois chiffres de la même fenêtre, faits pour être comparés entre eux
      // et avec les tuiles : ils s'alignent comme le reste.
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textMuted,
        fontFeatures: AppTextStyles.tabularFigures,
      ),
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

/// Pourquoi deux lignes portent le même numéro de pièce.
///
/// **Sans elle, le lecteur voit un doublon.** Le panier mixte est la seule
/// chose que cette table ait gagnée en passant à toutes les caisses : les deux
/// moitiés d'un versement, jusqu'ici rangées dans deux tables différentes, y
/// sont maintenant voisines sous un numéro identique.
///
/// Même forme que la note boutique de « Par source » : un encart discret, une
/// icône qui double le texte, et rien à cliquer.
class _SplitTenderNote extends StatelessWidget {
  final AppLocalizations l10n;

  const _SplitTenderNote({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.call_split_rounded,
            size: 16,
            color: AppColors.bleuArdoise,
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              l10n.financeTillReceiptsSplitTenderNote,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
