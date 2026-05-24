import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_stats_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_stats_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_stats_state.dart';
import 'package:school_app_flutter/features/classes/presentation/extensions/classroom_stats_error_l10n_extension.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_stats_dashboard_header.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_stats_error_view.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_stats_loading_view.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_stats_success_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesStatsDashboardPage extends StatefulWidget {
  const ClassesStatsDashboardPage({super.key});

  @override
  State<ClassesStatsDashboardPage> createState() =>
      _ClassesStatsDashboardPageState();
}

class _ClassesStatsDashboardPageState extends State<ClassesStatsDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<ClassroomStatsBloc>().add(const ClassroomStatsRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPageBackground(
      scrollable: true,
      child: BlocConsumer<ClassroomStatsBloc, ClassroomStatsState>(
        listenWhen: (prev, curr) =>
            prev.status != curr.status || prev.errorType != curr.errorType,
        listener: (context, state) {
          if (state.status == ClassroomStatsStatus.error) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorType.localizedMessage(l10n))),
            );
          }
        },
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.stats != curr.stats,
        builder: (context, state) {
          final schoolYear =
              state.stats?.context.academicYearName ??
              l10n.classesStatsSchoolYearUnavailable;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClassesStatsDashboardHeader(schoolYear: schoolYear, l10n: l10n),
              const SizedBox(height: AppDimensions.spacingL),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: KeyedSubtree(
                  key: ValueKey<ClassroomStatsStatus>(state.status),
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
    ClassroomStatsState state,
    AppLocalizations l10n,
  ) {
    return switch (state.status) {
      ClassroomStatsStatus.loading => const ClassesStatsLoadingView(),
      ClassroomStatsStatus.success => ClassesStatsSuccessView(
        stats: state.stats!,
      ),
      ClassroomStatsStatus.error => ClassesStatsErrorView(
        message: state.errorType.localizedMessage(l10n),
        onRetry: () => context.read<ClassroomStatsBloc>().add(
          const ClassroomStatsRefreshRequested(),
        ),
        l10n: l10n,
      ),
      ClassroomStatsStatus.initial => const SizedBox.shrink(),
    };
  }
}
