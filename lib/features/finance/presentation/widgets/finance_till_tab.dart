import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_loading_view.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_period_filter.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_success_view.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/states/finance_stats_results_error_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'onglet **Caisse** : ce qui est entré dans le tiroir sur la fenêtre.
class FinanceTillTab extends StatelessWidget {
  const FinanceTillTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: FinanceTillPeriodFilter(),
        ),
        const SizedBox(height: AppDimensions.spacingL),
        _body(context, l10n),
      ],
    );
  }

  /// Le corps de l'onglet, sous un sélecteur qui, lui, ne clignote pas :
  /// faire disparaître le contrôle qu'on vient d'actionner pendant le
  /// chargement rendrait la bascule de grain impossible à répéter.
  Widget _body(BuildContext context, AppLocalizations l10n) {
    return BlocBuilder<FinanceTillBloc, FinanceTillState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.till != curr.till ||
          prev.failure != curr.failure,
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: AppMotion.standard,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<FinanceTillStatus>(state.status),
            child: switch (state.status) {
              // Trois cartes, pas quatre : la caisse ne compte aucun taux.
              FinanceTillStatus.loading => const FinanceStatsLoadingView(
                kpiCount: 3,
              ),
              FinanceTillStatus.success => FinanceTillSuccessView(
                till: state.till!,
              ),
              FinanceTillStatus.error => FinanceStatsResultsErrorState(
                failure:
                    state.failure ?? const ServerFailure('unknown failure'),
                onRetry: () => context.read<FinanceTillBloc>().add(
                  const FinanceTillRefreshRequested(),
                ),
              ),
              FinanceTillStatus.initial => const SizedBox.shrink(),
            },
          ),
        );
      },
    );
  }
}
