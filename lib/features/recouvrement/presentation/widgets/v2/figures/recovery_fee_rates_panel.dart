import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/recouvrement_v2_tones.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_fee_rate_row.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_figures_support.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bloc C · « Taux de recouvrement par frais » (spec §4.6 C, R6, D6).
///
/// Un groupe par devise — dollars, puis francs — avec sa pastille et sa
/// synthèse « {perçu} sur {attendu} · {taux} % recouvrés », calculée sur les
/// seules lignes de **cette** devise ; puis une ligne par frais. Les libellés
/// viennent du serveur ([RecoveryFeeRate.label]).
///
/// Sous [AppBreakpoints.dataTableCardsMax] reçus, chaque ligne s'empile.
class RecoveryFeeRatesPanel extends StatelessWidget {
  final RecoveryDashboard dashboard;

  const RecoveryFeeRatesPanel({super.key, required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rates = dashboard.feeRates;
    if (rates.isEmpty) return const SizedBox.shrink();

    final retained = {for (final r in rates) r.feeCode}.length;
    final suffix = retained == 1
        ? l10n.recoveryRatesSubtitleOne
        : retained >= dashboard.fees.length && dashboard.fees.length > 1
        ? l10n.recoveryRatesSubtitleAll(retained)
        : l10n.recoveryRatesSubtitleMany(retained);

    final groups = <String, List<RecoveryFeeRate>>{};
    for (final rate in RecoveryFiguresSupport.byCurrency(
      rates,
      (r) => r.figures.currency,
    )) {
      groups.putIfAbsent(rate.figures.currency, () => []).add(rate);
    }

    return EteeloStatsCard(
      title: l10n.recoveryRatesTitle,
      subtitle: suffix,
      icon: Icons.percent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stacked =
              constraints.maxWidth < AppBreakpoints.dataTableCardsMax;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final entry in groups.entries)
                _CurrencyGroup(
                  currency: entry.key,
                  rates: entry.value,
                  fees: dashboard.fees,
                  stacked: stacked,
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CurrencyGroup extends StatelessWidget {
  final String currency;
  final List<RecoveryFeeRate> rates;
  final List<RecoveryFee> fees;
  final bool stacked;

  const _CurrencyGroup({
    required this.currency,
    required this.rates,
    required this.fees,
    required this.stacked,
  });

  /// Le bandeau de devise : son fond pâle à 40 % (`soft + '66'`).
  static const double _bandVeil = 0.4;

  /// La couleur d'un frais : celle de sa pastille dans le choix des frais.
  Color _colorOf(String feeCode) {
    final index = fees.indexWhere((f) => f.code == feeCode);
    return RecouvrementV2Tones.feeColor(index < 0 ? 0 : index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = RecoveryFiguresSupport.currencyTone(currency);

    // Sommes de cette devise seulement ; le taux comme le serveur :
    // (attendu − reste) / attendu, arrondi.
    var due = 0, paid = 0, outstanding = 0, heaviest = 0;
    for (final r in rates) {
      due += r.figures.dueInCents;
      paid += r.figures.paidInCents;
      outstanding += r.figures.outstandingInCents;
      if (r.figures.dueInCents > heaviest) heaviest = r.figures.dueInCents;
    }
    final collected = MoneyFormat.compact(Money(paid, currency));
    final expected = MoneyFormat.compact(Money(due, currency));
    final summary = due > 0
        ? l10n.recoveryRatesGroupSummary(
            collected,
            expected,
            ((due - outstanding) * 100 / due).round(),
          )
        : l10n.recoveryRatesGroupSummaryNoDue(collected, expected);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingS,
              vertical: AppDimensions.spacingS,
            ),
            decoration: BoxDecoration(
              color: tone.soft.withValues(alpha: _bandVeil),
              border: const Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Wrap(
              spacing: AppDimensions.spacingS,
              runSpacing: AppDimensions.spacingXS,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _CurrencyChip(currency: currency, tone: tone),
                Text(
                  summary,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontFeatures: AppTextStyles.tabularFigures,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXS),
          for (final rate in rates)
            RecoveryFeeRateRow(
              rate: rate,
              color: _colorOf(rate.feeCode),
              heaviestDueInCents: heaviest,
              stacked: stacked,
            ),
        ],
      ),
    );
  }
}

/// « $ Frais en dollars » (`FinDevChip` de la maquette).
class _CurrencyChip extends StatelessWidget {
  final String currency;
  final ({Color ink, Color soft, Color border}) tone;

  const _CurrencyChip({required this.currency, required this.tone});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS / 2,
      ),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: BorderRadius.circular(
          AppDimensions.recouvrementFeeChipRadius,
        ),
        border: Border.all(color: tone.border),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: '${MoneyFormat.symbolOf(currency)} ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: l10n.recoveryRatesCurrencyChip(currency)),
          ],
        ),
        maxLines: 1,
        softWrap: false,
        style: AppTextStyles.badge.copyWith(color: tone.ink),
      ),
    );
  }
}
