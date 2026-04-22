import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/domain/entities/bootstrap_school_level_group_bundle.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_previous_year_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_data_table.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/re_registration_search_form.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

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
      context.read<BootstrapPreviousYearBloc>().add(
        BootstrapContextLocalRequested(
          key: AppConstants.bootstrapPreviousYearPayloadKey,
        ),
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
          child: BlocBuilder<BootstrapPreviousYearBloc, BootstrapContextState>(
            builder: (context, bootstrapState) {
              final schoolId = context.select(
                (AuthBloc bloc) => bloc.state.user?.schoolId ?? '',
              );

              if (bootstrapState.status == BootstrapContextLoadStatus.loading ||
                  bootstrapState.status == BootstrapContextLoadStatus.initial) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (bootstrapState.status != BootstrapContextLoadStatus.success ||
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
                              page: 0,
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
                        totalCount: state.summariesTotalElements,
                        onViewRequested: (summary) {
                          final intent = EnrollmentDetailIntent.reRegistration(
                            enrollmentId: summary.enrollmentId,
                            studentId: summary.student.id,
                          );
                          context.push(
                            Uri(
                              path:
                                  '${EnrollmentConstants.enrollmentDetailRoute}/${summary.enrollmentId}',
                              queryParameters: intent.toQueryParameters(),
                            ).toString(),
                            extra: intent,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  BlocBuilder<EnrollmentBloc, EnrollmentState>(
                    buildWhen: (previous, current) =>
                        previous.summariesPage != current.summariesPage ||
                        previous.summariesTotalPages != current.summariesTotalPages ||
                        previous.summariesStatus != current.summariesStatus,
                    builder: (context, state) {
                      if (state.summariesTotalPages <= 1) {
                        return const SizedBox.shrink();
                      }

                      return _PaginationBar(
                        currentPage: state.summariesPage,
                        totalPages: state.summariesTotalPages,
                        isLoading:
                            state.summariesStatus == EnrollmentLoadStatus.loading,
                        onPrevious: () => context.read<EnrollmentBloc>().add(
                          EnrollmentSummariesPageRequested(
                            page: state.summariesPage - 1,
                          ),
                        ),
                        onNext: () => context.read<EnrollmentBloc>().add(
                          EnrollmentSummariesPageRequested(
                            page: state.summariesPage + 1,
                          ),
                        ),
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
    final seenKeys = <String>{};

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
        final option = ReRegistrationAcademicOption(
          schoolLevelGroupId: bundle.schoolLevelGroup.id,
          schoolLevelId: levelBundle.schoolLevel.id,
          label:
              '${bundle.schoolLevelGroup.name} - ${levelBundle.schoolLevel.name}',
        );

        if (seenKeys.add(option.key)) {
          options.add(option);
        }
      }
    }

    return options;
  }
}

class _SearchInvitationCard extends StatelessWidget {
  const _SearchInvitationCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 44, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.manage_search_rounded,
            size: 44,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 10),
          Text(
            l10n.reRegistrationSearchInvitationTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.reRegistrationSearchInvitationMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
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

class _PaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          l10n.enrollmentPageIndicator(currentPage + 1, totalPages),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: !isLoading && currentPage > 0 ? onPrevious : null,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: l10n.previous,
        ),
        IconButton(
          onPressed: !isLoading && currentPage + 1 < totalPages ? onNext : null,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: l10n.next,
        ),
      ],
    );
  }
}
