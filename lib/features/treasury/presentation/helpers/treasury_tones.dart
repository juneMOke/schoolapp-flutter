import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/components/tables/data_table_tone.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';

/// Un ton de la trésorerie : l'encre, le fond clair, la bordure.
typedef TreasuryTone = ({Color ink, Color soft, Color border});

/// Les couleurs de la trésorerie, composées une fois (spec §05). La colonne
/// « Usage » de la spec dit quand chacune s'applique : une caisse en dollars
/// est bleue partout, l'ouverture terre cuite partout, les entrées vertes,
/// les sorties rouges.
abstract final class TreasuryTones {
  static const TreasuryTone opening = (
    ink: AppColors.treasuryOpeningInk,
    soft: AppColors.treasuryOpeningSoft,
    border: AppColors.treasuryOpeningBorder,
  );
  static const TreasuryTone inflow = (
    ink: AppColors.treasuryCdfInk,
    soft: AppColors.treasuryCdfSoft,
    border: AppColors.treasuryCdfBorder,
  );
  static const TreasuryTone outflow = (
    ink: AppColors.treasuryOutflowInk,
    soft: AppColors.treasuryOutflowSoft,
    border: AppColors.treasuryOutflowBorder,
  );
  static const TreasuryTone pending = (
    ink: AppColors.treasuryPendingInk,
    soft: AppColors.treasuryPendingSoft,
    border: AppColors.treasuryPendingBorder,
  );

  /// Ce qui est propre à une caisse : sa courbe, son encadré, sa pastille.
  static TreasuryTone currency(TreasuryCurrency currency) => switch (currency) {
    TreasuryCurrency.usd => (
      ink: AppColors.treasuryUsdInk,
      soft: AppColors.treasuryUsdSoft,
      border: AppColors.treasuryUsdBorder,
    ),
    TreasuryCurrency.cdf => (
      ink: AppColors.treasuryCdfInk,
      soft: AppColors.treasuryCdfSoft,
      border: AppColors.treasuryCdfBorder,
    ),
  };

  /// Le fond des cartes de caisse et des boîtes d'icône de devise : 125°,
  /// arrêts à 0, 70 et 100 %.
  static LinearGradient gradient(TreasuryCurrency currency) => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: const [0, 0.7, 1],
    colors: switch (currency) {
      TreasuryCurrency.usd => const [
        AppColors.treasuryUsdDeep,
        AppColors.treasuryUsdMid,
        AppColors.treasuryUsdEnd,
      ],
      TreasuryCurrency.cdf => const [
        AppColors.treasuryCdfDeep,
        AppColors.treasuryCdfMid,
        AppColors.treasuryCdfEnd,
      ],
    },
  );

  /// Les tableaux (rapports, jour par jour) : bandeau terre cuite assombri
  /// de 20 % vers le bleu profond, zébrure, cadre terre cuite à 26 %.
  static DataTableTone get table => DataTableTone(
    header: DashboardTones.entete(AppColors.terreCuite),
    headerInk: AppColors.treasuryTableHeaderInk,
    headerInkSorted: AppColors.treasuryTableHeaderInk,
    zebra: AppColors.treasuryTableZebra,
    border: ColorMix.tint(AppColors.border, AppColors.terreCuite, 26),
  );

  /// Le contrôle segmenté « terre cuite » des périodes et des rapports.
  static const SegmentedTabFilterStyle filter = SegmentedTabFilterStyle(
    backgroundColor: AppColors.papier,
    borderColor: AppColors.treasuryOpeningBorder,
    borderRadius: AppDimensions.treasuryFilterRadius,
    containerHeight: null,
    itemHeight: AppDimensions.treasuryFilterItemHeight,
    itemBorderRadius: AppDimensions.treasuryFilterItemRadius,
    itemPadding: EdgeInsets.symmetric(
      horizontal: AppDimensions.treasuryFilterItemPaddingH,
    ),
    selectedBackgroundColor: AppColors.terreCuite,
    selectedShadow: [
      BoxShadow(
        color: AppColors.treasuryFilterShadow,
        offset: Offset(0, 4),
        blurRadius: 10,
        spreadRadius: -4,
      ),
    ],
  );

  /// L'ombre des cartes et panneaux blancs.
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: AppColors.treasuryCardShadow,
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  /// L'ombre des cartes de caisse.
  static const List<BoxShadow> registerShadow = [
    BoxShadow(
      color: AppColors.treasuryRegisterShadow,
      offset: Offset(0, 14),
      blurRadius: 30,
      spreadRadius: -20,
    ),
  ];
}
