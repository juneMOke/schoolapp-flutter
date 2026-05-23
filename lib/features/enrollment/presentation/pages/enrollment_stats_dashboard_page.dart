import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_stats_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_dashboard_header.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_error_view.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_loading_view.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_period_filter.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stats_success_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Page principale du tableau de bord des statistiques d'inscriptions.
class EnrollmentStatsDashboardPage extends StatefulWidget {
  const EnrollmentStatsDashboardPage({super.key});

  @override
  State<EnrollmentStatsDashboardPage> createState() =>
      _EnrollmentStatsDashboardPageState();
}

class _EnrollmentStatsDashboardPageState
    extends State<EnrollmentStatsDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<EnrollmentStatsBloc>().add(const EnrollmentStatsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppPageBackground(
      scrollable: true,
      child: BlocConsumer<EnrollmentStatsBloc, EnrollmentStatsState>(
        listenWhen: (prev, curr) => prev.status != curr.status,
        listener: (context, state) {
          if (state.status == EnrollmentStatsStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ?? l10n.enrollmentStatsLoadingError,
                ),
              ),
            );
          }
        },
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.stats != curr.stats,
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EnrollmentStatsDashboardHeader(l10n: l10n, state: state),
              const SizedBox(height: AppDimensions.spacingL),
              const EnrollmentStatsPeriodFilter(),
              const SizedBox(height: AppDimensions.spacingL),
              _buildBody(context, state, l10n),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    EnrollmentStatsState state,
    AppLocalizations l10n,
  ) {
    return switch (state.status) {
      EnrollmentStatsStatus.loading => const EnrollmentStatsLoadingView(),
      EnrollmentStatsStatus.success => EnrollmentStatsSuccessView(stats: state.stats!),
      EnrollmentStatsStatus.error => EnrollmentStatsErrorView(
        message: state.errorMessage ?? l10n.enrollmentStatsLoadingError,
        onRetry: () => context.read<EnrollmentStatsBloc>().add(
          const EnrollmentStatsRefreshRequested(),
        ),
        l10n: l10n,
      ),
      EnrollmentStatsStatus.initial => const SizedBox.shrink(),
    };
  }
}