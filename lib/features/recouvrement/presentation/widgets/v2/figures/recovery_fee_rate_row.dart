import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/color_mix.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_dashboard.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/figures/recovery_figures_support.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne du bloc C : un frais dans sa devise.
///
/// * **Large** (`FinBarRows` de la maquette) : libellé et « reste … » ; la
///   barre ; le perçu et « {taux} % de {attendu} ».
/// * **Empilée** sous 600 reçus (`RecRateRowsCompact`) : libellé et perçu,
///   barre pleine largeur, « {taux} % de {attendu} » et « reste {montant} ».
///
/// ⚠️ Écart assumé à `EteeloBarRows` : sa barre ne porte qu'une proportion et
/// sa valeur une ligne. Ici la **piste** porte le poids du frais dans
/// l'attendu de sa devise et le **remplissage** son taux — un petit frais à
/// 40 % se lit à côté d'un gros à 80 % — et la valeur tient sur deux lignes.
class RecoveryFeeRateRow extends StatelessWidget {
  final RecoveryFeeRate rate;
  final Color color;

  /// Le plus gros attendu du groupe : sa piste occupe toute la largeur.
  final int heaviestDueInCents;
  final bool stacked;

  const RecoveryFeeRateRow({
    super.key,
    required this.rate,
    required this.color,
    required this.heaviestDueInCents,
    required this.stacked,
  });

  /// Les colonnes de la maquette en disposition large : `1.15fr` / `2.5fr` / `1fr`.
  static const int _labelFlex = 23;
  static const int _barFlex = 50;
  static const int _valueFlex = 22;

  /// Un frais facturé à personne (R1) : « — » au lieu d'un taux.
  bool get _notBilled =>
      rate.billedStudents == 0 || rate.figures.dueInCents <= 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final f = rate.figures;
    final dash = l10n.recouvrementNoAmountDash;
    final collected = MoneyFormat.compact(f.paid);
    final expected = MoneyFormat.compact(f.due);
    final remaining = MoneyFormat.compact(f.outstanding);
    final percent = _notBilled ? null : f.ratePercent;

    final rateOf = percent == null
        ? dash
        : l10n.recoveryRatesRowRateOf(percent, expected);
    final rest = _notBilled ? dash : l10n.recoveryRatesRowRemaining(remaining);
    final bar = _RateBar(
      color: color,
      weight: stacked || heaviestDueInCents <= 0
          ? 1
          : (f.dueInCents / heaviestDueInCents).clamp(
              AppDimensions.recoveryRateTrackMinFraction,
              1.0,
            ),
      fill: percent == null ? 0 : percent / 100,
    );

    final strong = AppTextStyles.bodyStrong.copyWith(
      color: AppColors.textPrimary,
      fontFeatures: AppTextStyles.tabularFigures,
    );
    final rateStyle = AppTextStyles.caption.copyWith(
      color: RecoveryFiguresSupport.rateInk(percent),
      fontFeatures: AppTextStyles.tabularFigures,
    );
    final restStyle = AppTextStyles.caption.copyWith(
      color: _notBilled ? AppColors.textMutedAa : AppColors.error,
      fontFeatures: AppTextStyles.tabularFigures,
    );
    final label = Text(
      rate.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textPrimary),
    );
    Text nowrap(String s, TextStyle style) =>
        Text(s, maxLines: 1, softWrap: false, style: style);

    final content = stacked
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: label),
                  const SizedBox(width: AppDimensions.spacingS),
                  nowrap(
                    collected,
                    strong.copyWith(
                      color: DashboardTones.encreLisible(
                        DashboardSense.encaisse,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppDimensions.spacingS),
              bar,
              const SizedBox(height: AppDimensions.spacingXS),
              // Taux et reste se partagent la ligne, ou passent l'un sous
              // l'autre au texte grossi : aucun chiffre n'est coupé.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: AppDimensions.spacingS,
                children: [nowrap(rateOf, rateStyle), nowrap(rest, restStyle)],
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                flex: _labelFlex,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    label,
                    Text(
                      rest,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: restStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(flex: _barFlex, child: bar),
              const SizedBox(width: AppDimensions.spacingM),
              // Colonne de même part sur chaque ligne : les barres d'un groupe
              // s'alignent. Un montant trop long se réduit, jamais coupé.
              Expanded(
                flex: _valueFlex,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final (text, style) in [
                      (collected, strong),
                      (rateOf, rateStyle),
                    ])
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: nowrap(text, style),
                      ),
                  ],
                ),
              ),
            ],
          );

    return Semantics(
      container: true,
      label: _notBilled
          ? l10n.recoveryRatesRowNotBilledA11y(rate.label)
          : l10n.recoveryRatesRowA11y(
              rate.label,
              collected,
              expected,
              percent ?? 0,
              remaining,
            ),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingS,
          vertical: AppDimensions.spacingS,
        ),
        child: content,
      ),
    );
  }
}

/// La piste (poids) et son remplissage (taux), en dégradé de la couleur du
/// frais — `FinBarRows` de la maquette.
class _RateBar extends StatelessWidget {
  final Color color;
  final double weight;
  final double fill;

  const _RateBar({
    required this.color,
    required this.weight,
    required this.fill,
  });

  /// Les mélanges de la maquette : piste à 8 %, bord à 18 %, dégradé à 78 %.
  static const int _trackPercent = 8;
  static const int _borderPercent = 18;
  static const double _gradientStart = 0.78;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final radius = BorderRadius.circular(
      AppDimensions.recouvrementRateBarRadius,
    );

    Widget barAt(double t) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: weight,
      child: Container(
        height: AppDimensions.recouvrementRateBarHeight,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: ColorMix.tint(AppColors.surfaceAlt, color, _trackPercent),
          borderRadius: radius,
          border: Border.all(
            color: ColorMix.tint(AppColors.border, color, _borderPercent),
          ),
        ),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: (fill * t).clamp(0.0, 1.0),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: _gradientStart),
                  color,
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return ExcludeSemantics(
      child: reduceMotion
          ? barAt(1)
          : TweenAnimationBuilder<double>(
              key: ValueKey<double>(fill),
              tween: Tween<double>(begin: 0, end: 1),
              duration: AppMotion.layout,
              curve: AppMotion.outCurve,
              builder: (context, t, _) => barAt(t),
            ),
    );
  }
}
