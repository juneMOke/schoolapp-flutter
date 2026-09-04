import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/fee_control/presentation/bloc/fee_control_dashboard_bloc.dart';
import 'package:school_app_flutter/features/fee_control/presentation/helpers/fee_control_summary_cards.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bandeau du tableau de bord — **la même anatomie que celui de l'écran
/// nominatif**, sur un périmètre plus large : concernés, soldés, partiels, sans
/// paiement.
///
/// Les cartes viennent de `feeControlSummaryCards`, partagé avec l'autre écran.
/// C'est ce qui garantit qu'un même état porte le même nom, la même teinte et
/// le même arrondi de part, d'un écran à l'autre du module.
///
/// **Aucun anneau à côté.** Les quatre cartes portent déjà leur part ; un
/// second graphique redirait ces trois nombres sans rien ajouter.
class FeeControlDashboardSummaryBand extends StatelessWidget {
  const FeeControlDashboardSummaryBand({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<FeeControlDashboardBloc, FeeControlDashboardState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.summary != curr.summary ||
          prev.unbilled != curr.unbilled,
      builder: (context, state) {
        // Rien à annoncer tant qu'aucune lecture n'a abouti, ni quand personne
        // n'est concerné : l'état vide du classement le dit déjà, et quatre
        // zéros n'ajouteraient qu'un plancher de bruit.
        final show =
            state.status == EnrollmentLoadStatus.success &&
            !state.summary.isEmpty;

        return AnimatedSwitcher(
          duration: AppMotion.layout,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: show
              ? Padding(
                  key: const ValueKey('fee-control-dashboard-summary'),
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.spacingM,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        container: true,
                        label: l10n.feeControlSummaryA11yLabel,
                        child: EteeloKpiBand(
                          cards: feeControlSummaryCards(
                            state.summary.total,
                            l10n,
                          ),
                        ),
                      ),
                      _RemainingNote(remaining: state.summary.remaining),
                      _UnbilledNote(count: state.unbilled),
                    ],
                  ),
                )
              : const SizedBox.shrink(
                  key: ValueKey('fee-control-dashboard-summary-off'),
                ),
        );
      },
    );
  }
}

/// Ce qu'il reste à encaisser sur le périmètre, **par devise**.
///
/// En second rang, sous les compteurs : l'écran compte des personnes, et c'est
/// ce qui le rend lisible — un taux d'élèves n'additionne jamais des francs et
/// des dollars. Le montant, lui, ne se dit qu'en séparant les devises : les
/// sommer écrirait un nombre qui n'existe pas.
///
/// Silencieux quand il ne reste rien : une ligne « 0 » n'apprend rien de plus
/// que les quatre cartes au-dessus.
class _RemainingNote extends StatelessWidget {
  final MoneyBag remaining;

  const _RemainingNote({required this.remaining});

  @override
  Widget build(BuildContext context) {
    final entries = remaining.entries.where((m) => m.amountInCents > 0);
    if (entries.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingS),
      child: Text(
        l10n.feeControlDashboardRemaining(
          entries.map(MoneyFormat.format).join(' · '),
        ),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Les inscrits que ce frais ne concerne pas — **à côté du taux, jamais
/// dedans**.
///
/// Un élève sans créance de ce frais n'est pas un mauvais payeur : il n'est pas
/// facturé. Le fondre dans le dénominateur ferait chuter le taux d'une classe
/// pour une raison étrangère au recouvrement. Le taire, en revanche, laisserait
/// croire que tout le monde est compté.
///
/// Silencieux quand le compte est inconnu — lecture non faite ou échouée — et
/// quand il vaut zéro : il n'y a alors rien à signaler.
class _UnbilledNote extends StatelessWidget {
  final int? count;

  const _UnbilledNote({required this.count});

  @override
  Widget build(BuildContext context) {
    final value = count;
    if (value == null || value <= 0) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: AppDimensions.spacingS),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Flexible(
            child: Text(
              l10n.feeControlDashboardUnbilled(value),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
