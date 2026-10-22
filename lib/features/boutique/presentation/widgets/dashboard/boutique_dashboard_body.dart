import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/boutique_top_article.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/sale_history_entry.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_dashboard_bloc.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_dashboard_content.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_dashboard_empty_state.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/dashboard/boutique_dashboard_skeleton.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/states/boutique_results_error_state.dart';

/// Ce qui vit sous l'en-tête, selon l'état : squelette, erreur, vide, ou
/// l'écran prêt.
class BoutiqueDashboardBody extends StatelessWidget {
  final BoutiqueDashboardState state;
  final DateTime now;
  final GlobalKey beneficiariesKey;
  final void Function(BoutiqueTopArticle article) onArticleTap;
  final ValueChanged<SaleHistoryEntry> onOpenSale;
  final VoidCallback onOpenTill;

  /// Les valeurs restent affichées, atténuées, pendant qu'une autre période se
  /// charge : pas de squelette plein écran qui ferait clignoter la page.
  static const double _refreshingOpacity = 0.5;

  const BoutiqueDashboardBody({
    super.key,
    required this.state,
    required this.now,
    required this.beneficiariesKey,
    required this.onArticleTap,
    required this.onOpenSale,
    required this.onOpenTill,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<BoutiqueDashboardBloc>();
    final stats = state.stats;
    final window = state.window;

    switch (state.status) {
      case BoutiqueDashboardStatus.initial:
      case BoutiqueDashboardStatus.loading:
        return const BoutiqueDashboardSkeleton();
      case BoutiqueDashboardStatus.failure:
        return BoutiqueResultsErrorState(
          failure: state.failure!,
          surface: BoutiqueErrorSurface.dashboard,
          onRetry: () => bloc.add(const BoutiqueDashboardRefreshRequested()),
          onReconnect: () =>
              context.read<AuthBloc>().add(const AuthLogoutRequested()),
        );
      case BoutiqueDashboardStatus.ready:
        if (stats == null || window == null) {
          return const BoutiqueDashboardSkeleton();
        }
        final Widget child = state.isEmpty
            ? BoutiqueDashboardEmptyState(
                period: state.period,
                window: stats.window,
                onOpenTill: onOpenTill,
              )
            : BoutiqueDashboardContent(
                state: state,
                stats: stats,
                now: now,
                beneficiariesKey: beneficiariesKey,
                onCurrencySelected: (currency) =>
                    bloc.add(BoutiqueDashboardCurrencySelected(currency)),
                onArticleTap: onArticleTap,
                onOpenSale: onOpenSale,
                onOpenTill: onOpenTill,
              );
        return AnimatedOpacity(
          opacity: state.refreshing ? _refreshingOpacity : 1,
          duration: AppMotion.standard,
          child: IgnorePointer(ignoring: state.refreshing, child: child),
        );
    }
  }
}
