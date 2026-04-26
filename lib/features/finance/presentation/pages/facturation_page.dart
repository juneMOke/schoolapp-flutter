import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group_bundle.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_page_background.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_page_header.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_form.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_student_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class FacturationPage extends StatefulWidget {
  const FacturationPage({super.key});

  @override
  State<FacturationPage> createState() => _FacturationPageState();
}

class _FacturationPageState extends State<FacturationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BootstrapCurrentYearBloc>().add(
        const BootstrapContextLocalRequested(
          key: AppConstants.bootstrapPayloadKey,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FinancePageBackground(
      child: BlocBuilder<BootstrapCurrentYearBloc, BootstrapContextState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.bootstrap != curr.bootstrap,
        builder: (context, bootstrapState) {
          if (bootstrapState.status == BootstrapContextLoadStatus.loading ||
              bootstrapState.status == BootstrapContextLoadStatus.initial) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (bootstrapState.status != BootstrapContextLoadStatus.success) {
            return BootstrapContextError(
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            );
          }

          final academicOptions = _buildAcademicOptions(
            bootstrapState.bootstrap?.schoolLevelGroups ?? const [],
          );

          return AnimatedSwitcher(
            duration: FinanceMotion.standard,
            child: Column(
              key: const ValueKey('facturation-content'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FacturationPageHeader(),
                const SizedBox(height: AppDimensions.spacingM),
                BlocBuilder<EnrollmentBloc, EnrollmentState>(
                  buildWhen: (prev, curr) =>
                      prev.summariesStatus != curr.summariesStatus,
                  builder: (context, enrollmentState) {
                    return FacturationSearchForm(
                      options: academicOptions,
                      isLoading:
                          enrollmentState.summariesStatus == EnrollmentLoadStatus.loading,
                      onSearch: (request) => context.read<EnrollmentBloc>().add(
                        EnrollmentSummariesByAcademicInfoRequested(
                          firstName: request.firstName,
                          lastName: request.lastName,
                          surname: request.surname,
                          schoolLevelGroupId: request.schoolLevelGroupId,
                          schoolLevelId: request.schoolLevelId,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.spacingM),
                FacturationStudentTable(
                  onViewRequested: _onViewChargesRequested,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Construit les options cycle/niveau à partir du bootstrap année courante,
  /// triées par ordre d'affichage — même logique que ReRegistrationsPage.
  List<FacturationLevelOption> _buildAcademicOptions(
    List<BootstrapSchoolLevelGroupBundle> bundles,
  ) {
    final options = <FacturationLevelOption>[];
    final seen = <String>{};

    final sorted = [...bundles]
      ..sort(
        (a, b) => a.schoolLevelGroup.displayOrder
            .compareTo(b.schoolLevelGroup.displayOrder),
      );

    for (final bundle in sorted) {
      final sortedLevels = [...bundle.schoolLevels]
        ..sort(
          (a, b) => a.schoolLevel.displayOrder
              .compareTo(b.schoolLevel.displayOrder),
        );

      for (final levelBundle in sortedLevels) {
        final option = FacturationLevelOption(
          schoolLevelGroupId: bundle.schoolLevelGroup.id,
          schoolLevelId: levelBundle.schoolLevel.id,
          label:
              '${bundle.schoolLevelGroup.name} - ${levelBundle.schoolLevel.name}',
        );
        if (seen.add(option.key)) {
          options.add(option);
        }
      }
    }

    return options;
  }

  /// Navigue vers la page de détail facturation avec le contexte d'affichage.
  void _onViewChargesRequested(EnrollmentSummary summary, String levelId) {
    final l10n = AppLocalizations.of(context)!;
    final bootstrap = context.read<BootstrapCurrentYearBloc>().state.bootstrap;
    final academicYearId = bootstrap?.academicYear.id ?? '';

    if (academicYearId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bootstrapContextUnavailableMessage)),
      );
      return;
    }

    String levelName = '';
    String levelGroupName = '';

    for (final groupBundle in bootstrap?.schoolLevelGroups ?? const []) {
      for (final levelBundle in groupBundle.schoolLevels) {
        if (levelBundle.schoolLevel.id == levelId) {
          levelName = levelBundle.schoolLevel.name;
          levelGroupName = groupBundle.schoolLevelGroup.name;
          break;
        }
      }
      if (levelName.isNotEmpty) {
        break;
      }
    }

    context.push(
      AppRoutesNames.facturationDetailPath(
        studentId: summary.student.id,
        academicYearId: academicYearId,
      ),
      extra: FacturationDetailIntent(
        studentId: summary.student.id,
        academicYearId: academicYearId,
        firstName: summary.student.firstName,
        lastName: summary.student.lastName,
        surname: summary.student.surname,
        levelName: levelName,
        levelGroupName: levelGroupName,
      ),
    );
  }
}