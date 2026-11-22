import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';

/// Outils communs aux blocs B et C du tableau de bord du Recouvrement.
class RecoveryFiguresSupport {
  const RecoveryFiguresSupport._();

  /// Les dollars d'abord, puis les francs, puis le reste dans l'ordre reçu :
  /// la maquette lit toujours « 130 920 $ » puis « 2 215 000 FC ».
  static int currencyRank(String currency) => switch (currency) {
    'USD' => 0,
    'CDF' => 1,
    _ => 2,
  };

  /// [items] triés par devise ([currencyRank]), ordre stable sinon.
  static List<T> byCurrency<T>(List<T> items, String Function(T) currencyOf) {
    final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
    indexed.sort((a, b) {
      final rank =
          currencyRank(currencyOf(a.$2)) - currencyRank(currencyOf(b.$2));
      return rank != 0 ? rank : a.$1 - b.$1;
    });
    return [for (final entry in indexed) entry.$2];
  }

  /// Les chiffres de tête, dollars puis francs.
  static List<RecoveryFigures> orderedFigures(RecoveryDashboard dashboard) =>
      byCurrency(dashboard.keyFigures, (f) => f.currency);

  /// Une ligne par devise ; jamais un total entre devises (R2). Sans aucune
  /// devise (rien de facturé), un tiret.
  static List<String> amountLines(
    List<RecoveryFigures> figures,
    int Function(RecoveryFigures) cents,
    String dash,
  ) {
    if (figures.isEmpty) return [dash];
    return [
      for (final f in figures) MoneyFormat.compact(Money(cents(f), f.currency)),
    ];
  }

  /// Encre du taux d'un frais, selon la maquette (`FinBarRows`) : vert dès
  /// 80 %, ambre dès 45 %, rouge en deçà.
  static Color rateInk(int? rate) {
    if (rate == null) return AppColors.textMutedAa;
    if (rate >= 80) return DashboardTones.encreLisible(DashboardSense.encaisse);
    if (rate >= 45) return AppColors.ambreInk;
    return DashboardTones.encreLisible(DashboardSense.manquant);
  }

  /// Encre, fond et bord de la pastille d'une devise (`FinDevChip`).
  static ({Color ink, Color soft, Color border}) currencyTone(
    String currency,
  ) => currency == 'CDF'
      ? (
          ink: AppColors.treasuryCdfInk,
          soft: AppColors.treasuryCdfSoft,
          border: AppColors.treasuryCdfBorder,
        )
      : (
          ink: AppColors.treasuryUsdInk,
          soft: AppColors.treasuryUsdSoft,
          border: AppColors.treasuryUsdBorder,
        );
}
