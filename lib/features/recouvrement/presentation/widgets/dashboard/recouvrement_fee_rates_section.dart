import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/student_charges/student_charge_fee_code_l10n_extension.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le taux de recouvrement, **un groupe par devise**.
///
/// Jamais un classement unique : comparer un taux en francs à un taux en
/// dollars est légitime — ce sont des pourcentages — mais additionner leurs
/// montants ne l'est pas. Chaque groupe porte son en-tête chiffré, puis une
/// barre par poste.
///
/// **Longueur de la barre** = poids du poste dans l'attendu de sa devise.
/// **Remplissage** = ce qui est recouvré. Les deux disent deux choses
/// différentes, et c'est ce qui permet de voir d'un coup qu'un petit poste à
/// 40 % pèse moins qu'un gros poste à 80 %.
class RecouvrementFeeRatesSection extends StatelessWidget {
  /// Les groupes déjà projetés — la section ne relit rien elle-même.
  final List<RecouvrementCurrencyGroup> groups;

  const RecouvrementFeeRatesSection({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<RecouvrementDashboardBloc, RecouvrementDashboardState>(
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        if (state.status != EnrollmentLoadStatus.success || groups.isEmpty) {
          return const SizedBox.shrink();
        }

        final feeCount = state.lastQuery?.feeCodes.length ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
          child: Semantics(
            container: true,
            label: l10n.recouvrementRatesA11yLabel,
            child: BiToneSectionCard(
              title: l10n.recouvrementRatesTitle,
              subtitle: feeCount <= 1
                  ? l10n.recouvrementRatesSubtitleOne
                  : l10n.recouvrementRatesSubtitleMany(feeCount),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final group in groups) _CurrencyGroup(group: group),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CurrencyGroup extends StatelessWidget {
  final RecouvrementCurrencyGroup group;

  const _CurrencyGroup({required this.group});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final header = group.hasNoExpectation
        ? l10n.recouvrementRatesGroupHeaderNoExpectation(
            MoneyFormat.format(Money(group.paidInCents, group.currency)),
          )
        : l10n.recouvrementRatesGroupHeader(
            MoneyFormat.format(Money(group.paidInCents, group.currency)),
            MoneyFormat.format(Money(group.expectedInCents, group.currency)),
            group.rate,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingM,
              vertical: AppDimensions.spacingS,
            ),
            decoration: BoxDecoration(
              color: AppColors.bleuArdoiseSoft,
              borderRadius: BorderRadius.circular(AppDimensions.spacingS),
            ),
            child: Wrap(
              spacing: AppDimensions.spacingS,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  l10n.recouvrementCurrencyGroupTitle(
                    MoneyFormat.symbolOf(group.currency),
                  ),
                  style: AppTextStyles.bodyStrong,
                ),
                Text(
                  header,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          for (final fee in group.fees)
            _FeeRow(fee: fee, heaviest: group.heaviestExpectedInCents),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  final RecouvrementFeeRate fee;
  final int heaviest;

  const _FeeRow({required this.fee, required this.heaviest});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = fee.feeCode.localizedFeeLabel(l10n);
    final remaining = MoneyFormat.format(
      Money(fee.remainingInCents, fee.currency),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Semantics(
        // La barre est une image ; son sens est dit en toutes lettres, jamais
        // porté par la seule longueur.
        label: l10n.recouvrementRateBarA11y(label, fee.rate, remaining),
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.body),
                  Text(
                    fee.hasNoExpectation
                        ? l10n.recouvrementRateNoExpectation
                        : l10n.recouvrementRateRemaining(remaining),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              flex: 5,
              child: _Bar(fee: fee, heaviest: heaviest),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    // Un taux de 100 % sur un poste qui n'attendait rien serait
                    // un contresens : l'écran pose un tiret.
                    fee.hasNoExpectation
                        ? l10n.recouvrementNoAmountDash
                        : '${fee.rate} %',
                    style: AppTextStyles.bodyStrong,
                  ),
                  Text(
                    l10n.recouvrementRateExpected(
                      MoneyFormat.format(
                        Money(fee.expectedInCents, fee.currency),
                      ),
                    ),
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La piste porte le **poids** du poste, le remplissage son **taux**.
class _Bar extends StatelessWidget {
  final RecouvrementFeeRate fee;
  final int heaviest;

  const _Bar({required this.fee, required this.heaviest});

  @override
  Widget build(BuildContext context) {
    // Le poste le plus lourd occupe toute la largeur ; les autres s'y
    // rapportent. Un groupe sans attendu nulle part laisse les pistes à zéro
    // plutôt que de diviser par lui.
    final weight = heaviest <= 0
        ? 0.0
        : (fee.expectedInCents / heaviest).clamp(0.0, 1.0);
    final fill = fee.hasNoExpectation ? 0.0 : fee.rate / 100;

    return LayoutBuilder(
      builder: (context, constraints) => Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: constraints.maxWidth * weight,
          height: AppDimensions.recouvrementRateBarHeight,
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(
              AppDimensions.recouvrementRateBarRadius,
            ),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fill,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.bleuArdoise,
                borderRadius: BorderRadius.circular(
                  AppDimensions.recouvrementRateBarRadius,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
