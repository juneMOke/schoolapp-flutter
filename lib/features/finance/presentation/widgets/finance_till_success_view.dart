import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_buckets_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_fee_code_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_freshness_caption.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_kpi_band.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce qui est entré dans le tiroir sur la fenêtre.
///
/// Même composition que le recouvrement — bande KPI commune, puis un jeu de
/// sections par devise — parce que c'est le même écran et qu'il se lit de la
/// même façon. Ce qui diffère est ce qu'on y compte : ici rien n'est dû, rien
/// n'est attendu, et la moitié boutique existe.
class FinanceTillSuccessView extends StatelessWidget {
  final FinanceTill till;

  const FinanceTillSuccessView({super.key, required this.till});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WindowCaption(till: till, l10n: l10n),
        const SizedBox(height: AppDimensions.spacingM),
        if (till.byCurrency.isEmpty)
          // Ni catalogue, ni grille, ni mouvement : le serveur ne renvoie aucun
          // bloc. C'est un état vide, pas une erreur — et surtout pas un zéro
          // dans une unité que personne n'a choisie.
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppDimensions.spacingXL,
            ),
            child: EteeloEmptyResult(
              label: l10n.financeStatsNoMovementLabel,
              description: l10n.financeStatsNoMovementDescription,
              medallionIcon: Icons.point_of_sale_outlined,
            ),
          )
        else ...[
          FinanceTillKpiBand(blocks: till.byCurrency),
          const SizedBox(height: AppDimensions.spacingS),
          const FinanceTillFreshnessCaption(),
          const SizedBox(height: AppDimensions.spacingL),
          for (final block in till.byCurrency) ...[
            if (till.byCurrency.length > 1)
              _CurrencyHeading(currency: block.currency, l10n: l10n),
            if (block.hasNoMovement)
              _CurrencyNoMovement(l10n: l10n)
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final buckets = FinanceTillBucketsSection(
                    buckets: block.buckets,
                  );
                  final feeCodes = FinanceTillFeeCodeSection(
                    items: block.summary.byFeeCode,
                  );
                  if (constraints.maxWidth >=
                      AppBreakpoints.financeStatsTwoColMin) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: buckets),
                        const SizedBox(width: AppDimensions.spacingL),
                        Expanded(flex: 3, child: feeCodes),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buckets,
                      const SizedBox(height: AppDimensions.spacingL),
                      feeCodes,
                    ],
                  );
                },
              ),
            const SizedBox(height: AppDimensions.spacingXL),
          ],
        ],
      ],
    );
  }
}

/// De quelle fenêtre parle le total, et dans quel fuseau elle se découpe.
///
/// **Les bornes viennent du serveur** (`context.periodStart` / `periodEnd`),
/// jamais d'un `DateTime.now()` local : une journée de caisse commence et finit
/// dans le fuseau de l'école, et un encaissement sonné à 00 h 20 au guichet
/// porte un instant serveur de 23 h 20 Z la veille. Refaire la borne côté
/// tablette ferait diverger le total affiché de celui du serveur les nuits de
/// fin de journée.
class _WindowCaption extends StatelessWidget {
  final FinanceTill till;
  final AppLocalizations l10n;

  const _WindowCaption({required this.till, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final materialL10n = MaterialLocalizations.of(context);
    final start = materialL10n.formatMediumDate(till.context.periodStart);
    final end = materialL10n.formatMediumDate(till.context.periodEnd);
    final window = till.context.periodStart == till.context.periodEnd
        ? l10n.financeTillWindowDay(start)
        : l10n.financeTillWindow(start, end);

    return Wrap(
      spacing: AppDimensions.spacingM,
      runSpacing: AppDimensions.spacingXS,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          window,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        if (till.hasTimeZone)
          Text(
            l10n.financeTillTimeZoneHint(till.timeZone),
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
      ],
    );
  }
}

/// Une devise dans laquelle l'école facture ou vend, sans qu'un franc y ait
/// circulé sur la fenêtre.
///
/// **Le cas le plus fréquent de l'onglet** : le serveur garde ces blocs à zéro
/// plutôt que de les omettre, et une journée creuse en rendrait autant que
/// l'école a de devises.
class _CurrencyNoMovement extends StatelessWidget {
  final AppLocalizations l10n;

  const _CurrencyNoMovement({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${l10n.financeStatsCurrencyNoMovement}. '
          '${l10n.financeStatsCurrencyNoMovementTill}',
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
              const Icon(
                Icons.point_of_sale_outlined,
                size: 18,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.financeStatsCurrencyNoMovement,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    Text(
                      l10n.financeStatsCurrencyNoMovementTill,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Nomme la devise du bloc qui suit — seulement à partir de deux.
class _CurrencyHeading extends StatelessWidget {
  final String currency;
  final AppLocalizations l10n;

  const _CurrencyHeading({required this.currency, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingS),
      child: Semantics(
        header: true,
        child: Row(
          children: [
            Text(
              l10n.financeStatsCurrencyHeading(MoneyFormat.symbolOf(currency)),
              style: AppTextStyles.bodyStrong.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            const Expanded(child: Divider(height: 1, color: AppColors.border)),
          ],
        ),
      ),
    );
  }
}
