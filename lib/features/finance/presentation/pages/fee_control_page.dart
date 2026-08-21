import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/fee_control/fee_control_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/fee_control_page_helpers.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_results_view.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_search_form.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_summary_band.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Contrôle des frais : pour un frais d'une classe, qui est soldé, qui est
/// partiel, qui n'a rien versé.
///
/// Même anatomie que la Facturation (gate du contexte académique, formulaire
/// puis résultats), et l'œil rouvre **la fiche financière de la Facturation** —
/// aucune duplication du détail.
class FeeControlPage extends StatelessWidget {
  const FeeControlPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FeeControlBloc>(
      create: (_) => getIt<FeeControlBloc>(),
      child: const _FeeControlView(),
    );
  }
}

class _FeeControlView extends StatefulWidget {
  const _FeeControlView();

  @override
  State<_FeeControlView> createState() => _FeeControlViewState();
}

class _FeeControlViewState extends State<_FeeControlView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicYearContextBloc>().add(
        const AcademicYearContextRequested(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppPageBackground(
      child: BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
        buildWhen: (prev, curr) =>
            prev.status != curr.status || prev.context != curr.context,
        builder: (context, academicYearState) {
          if (academicYearState.status ==
                  AcademicYearContextLoadStatus.loading ||
              academicYearState.status ==
                  AcademicYearContextLoadStatus.initial) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (academicYearState.status !=
              AcademicYearContextLoadStatus.success) {
            return BootstrapContextError(
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            );
          }

          final academicYearId =
              academicYearState.context?.academicYear.id ?? '';
          final options = FeeControlPageHelpers.buildAcademicOptions(
            academicYearState.context?.schoolLevelGroups ?? const [],
          );

          return AnimatedSwitcher(
            duration: FinanceMotion.standard,
            child: Column(
              key: const ValueKey('fee-control-content'),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BlocBuilder<FeeControlBloc, FeeControlState>(
                  buildWhen: (prev, curr) =>
                      prev.status != curr.status ||
                      prev.tariffsStatus != curr.tariffsStatus ||
                      prev.tariffs != curr.tariffs ||
                      prev.classroomsStatus != curr.classroomsStatus ||
                      prev.classrooms != curr.classrooms ||
                      prev.feeGridMissing != curr.feeGridMissing,
                  builder: (context, state) {
                    final bloc = context.read<FeeControlBloc>();
                    return FeeControlSearchForm(
                      options: options,
                      tariffs: state.tariffs,
                      classrooms: state.classrooms,
                      isTariffsLoading:
                          state.tariffsStatus == EnrollmentLoadStatus.loading,
                      isClassroomsLoading:
                          state.classroomsStatus ==
                          EnrollmentLoadStatus.loading,
                      feeGridMissing: state.feeGridMissing,
                      // `tariffsStatus: failure` était stocké et lu par
                      // personne : le sélecteur de frais retombait alors sur
                      // « aucun frais défini pour ce niveau », qui affirme sur
                      // l'école ce qui n'est vrai que de cet appareil.
                      tariffsFailed:
                          state.tariffsStatus == EnrollmentLoadStatus.failure,
                      isLoading: state.status == EnrollmentLoadStatus.loading,
                      // Un niveau choisi ouvre deux lectures locales : sa grille
                      // tarifaire et ses classes.
                      onLevelSelected: (groupId, levelId) {
                        bloc.add(
                          FeeControlTariffsRequested(
                            academicYearId: academicYearId,
                            schoolLevelGroupId: groupId,
                            schoolLevelId: levelId,
                          ),
                        );
                        bloc.add(
                          FeeControlClassroomsRequested(
                            academicYearId: academicYearId,
                            schoolLevelId: levelId,
                          ),
                        );
                      },
                      onSearch: (request) => bloc.add(
                        FeeControlSearchRequested(
                          academicYearId: academicYearId,
                          request: request,
                        ),
                      ),
                      onClear: () => bloc.add(const FeeControlResetRequested()),
                    );
                  },
                ),
                const SizedBox(height: AppDimensions.spacingM),
                const FeeControlSummaryBand(),
                FeeControlResultsView(
                  onViewRequested: (row) =>
                      _openFinancialRecord(context, row, academicYearId),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Ouvre la fiche financière de l'élève — la page de détail de la
  /// Facturation, réutilisée telle quelle. Le retour revient ici : la page est
  /// **poussée**, et `StudentDetailAppBar` dépile avant de retomber sur sa
  /// route de repli.
  void _openFinancialRecord(
    BuildContext context,
    FeeControlRow row,
    String academicYearId,
  ) {
    final l10n = AppLocalizations.of(context)!;
    if (academicYearId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.bootstrapContextUnavailableMessage)),
      );
      return;
    }

    final levelId =
        context.read<FeeControlBloc>().state.lastQuery?.schoolLevelId ?? '';
    final academicYearContext = context
        .read<AcademicYearContextBloc>()
        .state
        .context;

    String levelName = '';
    String levelGroupName = '';
    for (final groupBundle
        in academicYearContext?.schoolLevelGroups ?? const []) {
      for (final level in groupBundle.levels) {
        if (level.id == levelId) {
          levelName = level.name;
          levelGroupName = groupBundle.group.name;
          break;
        }
      }
      if (levelName.isNotEmpty) break;
    }

    final student = row.summary.student;
    context.push(
      AppRoutesNames.facturationDetailPath(
        studentId: student.id,
        academicYearId: academicYearId,
      ),
      extra: FacturationDetailIntent(
        studentId: student.id,
        academicYearId: academicYearId,
        firstName: student.firstName,
        lastName: student.lastName,
        surname: student.surname,
        levelName: levelName,
        levelGroupName: levelGroupName,
      ),
    );
  }
}
