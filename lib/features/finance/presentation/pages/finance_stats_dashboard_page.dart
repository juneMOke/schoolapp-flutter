import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_stats_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/finance_stats_error_l10n_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_dashboard_header.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_error_view.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_loading_view.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_period_filter.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_stats_success_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class FinanceStatsDashboardPage extends StatefulWidget {
  const FinanceStatsDashboardPage({super.key});

  @override
  State<FinanceStatsDashboardPage> createState() =>
      _FinanceStatsDashboardPageState();
}

class _FinanceStatsDashboardPageState extends State<FinanceStatsDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<FinanceStatsBloc>().add(const FinanceStatsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPageBackground(
      scrollable: true,
      child: BlocConsumer<FinanceStatsBloc, FinanceStatsState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status || prev.errorType != curr.errorType,
        listener: (context, state) {
          if (state.status == FinanceStatsStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorType.localizedMessage(l10n))),
            );
          }
        },
        buildWhen: (prev, curr) =>
            prev.status != curr.status ||
            prev.stats != curr.stats ||
            prev.selectedPeriod != curr.selectedPeriod,
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FinanceStatsDashboardHeader(state: state, l10n: l10n),
              const SizedBox(height: AppDimensions.spacingL),
              _FinanceStatsContextFilterRow(state: state),
              const SizedBox(height: AppDimensions.spacingL),
              AnimatedSwitcher(
                duration: AppMotion.standard,
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey<FinanceStatsStatus>(state.status),
                  child: _buildBody(context, state, l10n),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    FinanceStatsState state,
    AppLocalizations l10n,
  ) {
    return switch (state.status) {
      FinanceStatsStatus.loading => const FinanceStatsLoadingView(),
      FinanceStatsStatus.success => FinanceStatsSuccessView(
        stats: state.stats!,
      ),
      FinanceStatsStatus.error => FinanceStatsErrorView(
        message: state.errorType.localizedMessage(l10n),
        onRetry: () => context.read<FinanceStatsBloc>().add(
          const FinanceStatsRefreshRequested(),
        ),
        l10n: l10n,
      ),
      FinanceStatsStatus.initial => const SizedBox.shrink(),
    };
  }
}

class _FinanceStatsContextFilterRow extends StatelessWidget {
  final FinanceStatsState state;

  const _FinanceStatsContextFilterRow({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final schoolYear =
        state.stats?.context.schoolYear ??
        l10n.financeStatsSchoolYearUnavailable;

    return Semantics(
      container: true,
      label: l10n.financeStatsContextSchoolYear(schoolYear),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        runSpacing: AppDimensions.spacingM,
        spacing: AppDimensions.spacingM,
        children: [
          ExcludeSemantics(
            child: Text(
              l10n.financeStatsContextSchoolYear(schoolYear),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          const FinanceStatsPeriodFilter(),
        ],
      ),
    );
  }
}
