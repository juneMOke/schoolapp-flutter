import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group_bundle.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_data_table.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/re_registration_search_form.dart';

class ReRegistrationsPage extends StatefulWidget {
  const ReRegistrationsPage({super.key});

  @override
  State<ReRegistrationsPage> createState() => _ReRegistrationsPageState();
}

class _ReRegistrationsPageState extends State<ReRegistrationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BootstrapBloc>().add(
        BootstrapLocalRequested(key: AppConstants.bootstrapPreviousYearPayloadKey),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F8FF), Color(0xFFEFF5FF), Color(0xFFF7FAFF)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.largePadding),
          child: BlocBuilder<BootstrapBloc, BootstrapState>(
            builder: (context, bootstrapState) {
              final schoolId = context.select(
                (AuthBloc bloc) => bloc.state.user?.schoolId ?? '',
              );

              if (bootstrapState.status == BootstrapLoadStatus.loading ||
                  bootstrapState.status == BootstrapLoadStatus.initial) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (bootstrapState.status != BootstrapLoadStatus.success ||
                  schoolId.isEmpty) {
                return BootstrapContextError(
                  onLogout: () =>
                      context.read<AuthBloc>().add(const AuthLogoutRequested()),
                );
              }

              final academicOptions = _buildAcademicOptions(
                bootstrapState.bootstrap?.schoolLevelGroups ?? const [],
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<EnrollmentBloc, EnrollmentState>(
                    buildWhen: (previous, current) =>
                        previous.summariesStatus != current.summariesStatus,
                    builder: (context, enrollmentState) {
                      final isLoading =
                          enrollmentState.summariesStatus ==
                          EnrollmentLoadStatus.loading;

                      return ReRegistrationSearchForm(
                        options: academicOptions,
                        isLoading: isLoading,
                        onSearch: (request) {
                          context.read<EnrollmentBloc>().add(
                            EnrollmentSummariesByAcademicInfoRequested(
                              firstName: request.firstName,
                              lastName: request.lastName,
                              surname: request.surname,
                              schoolLevelGroupId: request.schoolLevelGroupId,
                              schoolLevelId: request.schoolLevelId,
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  BlocBuilder<EnrollmentBloc, EnrollmentState>(
                    builder: (context, state) {
                      final hasAcademicSearch =
                          state.summariesQueryType ==
                          EnrollmentSummaryQueryType.byAcademicInfo;

                      if (!hasAcademicSearch) {
                        return const _SearchInvitationCard();
                      }

                      return EnrollmentDataTable(
                        isLoading:
                            state.summariesStatus ==
                            EnrollmentLoadStatus.loading,
                        enrollments: state.summaries,
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<ReRegistrationAcademicOption> _buildAcademicOptions(
    List<BootstrapSchoolLevelGroupBundle> bundles,
  ) {
    final options = <ReRegistrationAcademicOption>[];

    final sortedBundles = [...bundles]
      ..sort(
        (a, b) => a.schoolLevelGroup.displayOrder.compareTo(
          b.schoolLevelGroup.displayOrder,
        ),
      );

    for (final bundle in sortedBundles) {
      final sortedLevels = [...bundle.schoolLevels]
        ..sort(
          (a, b) =>
              a.schoolLevel.displayOrder.compareTo(b.schoolLevel.displayOrder),
        );

      for (final levelBundle in sortedLevels) {
        options.add(
          ReRegistrationAcademicOption(
            schoolLevelGroupId: bundle.schoolLevelGroup.id,
            schoolLevelId: levelBundle.schoolLevel.id,
            label: '${bundle.schoolLevelGroup.name} - ${levelBundle.schoolLevel.name}',
          ),
        );
      }
    }

    return options;
  }
}

class _SearchInvitationCard extends StatelessWidget {
  const _SearchInvitationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: 44,
            color: AppTheme.primaryColor,
          ),
          SizedBox(height: 10),
          Text(
            'Lancez une recherche de re-inscription',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Remplissez le formulaire ci-dessus puis cliquez sur Rechercher pour afficher les dossiers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
