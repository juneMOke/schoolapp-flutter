import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_recovery_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_loading_view.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_success_view.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/states/finance_stats_results_error_state.dart';

/// L'onglet **Recouvrement** : où en est l'école de l'argent qu'elle doit
/// encaisser cette année.
///
/// Aucun sélecteur de fenêtre — l'année scolaire courante, toujours. « Réessayer »
/// rejoue le même évènement que le premier chargement.
class FinanceRecoveryTab extends StatelessWidget {
  const FinanceRecoveryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FinanceRecoveryBloc, FinanceRecoveryState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status ||
          prev.recovery != curr.recovery ||
          prev.failure != curr.failure,
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: AppMotion.standard,
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: KeyedSubtree(
            key: ValueKey<FinanceRecoveryStatus>(state.status),
            child: switch (state.status) {
              FinanceRecoveryStatus.loading => const FinanceStatsLoadingView(),
              FinanceRecoveryStatus.success => FinanceStatsSuccessView(
                stats: state.recovery!,
              ),
              FinanceRecoveryStatus.error => FinanceStatsResultsErrorState(
                failure:
                    state.failure ?? const ServerFailure('unknown failure'),
                onRetry: () => context.read<FinanceRecoveryBloc>().add(
                  const FinanceRecoveryRequested(),
                ),
              ),
              FinanceRecoveryStatus.initial => const SizedBox.shrink(),
            },
          ),
        );
      },
    );
  }
}
