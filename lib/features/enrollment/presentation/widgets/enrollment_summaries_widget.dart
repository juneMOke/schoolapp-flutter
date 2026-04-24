import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/constants/enrollment_constants.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_data_table.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/pre_registrations_info_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form.dart';

class EnrollmentSummariesWidget extends StatefulWidget {
  final String status;
  final bool showStatusBadge;
  final bool showStatusFilter;
  final Widget? action;
  final EnrollmentDetailIntent Function(EnrollmentSummary summary)
  intentFactory;

  const EnrollmentSummariesWidget({
    super.key,
    required this.status,
    this.showStatusBadge = true,
    this.showStatusFilter = false,
    this.action,
    required this.intentFactory,
  });

  @override
  State<EnrollmentSummariesWidget> createState() =>
      _EnrollmentSummariesWidgetState();
}

class _EnrollmentSummariesWidgetState extends State<EnrollmentSummariesWidget> {
  static const Duration _refreshCooldown = Duration(milliseconds: 700);
  DateTime? _lastRefreshAt;

  /// Effective status used for queries. When [showStatusFilter] is true,
  /// this is managed locally (starts at IN_PROGRESS). Otherwise it mirrors
  /// the fixed [widget.status] supplied by the parent page.
  late String _effectiveStatus;

  @override
  void initState() {
    super.initState();
    _effectiveStatus = widget.showStatusFilter ? 'IN_PROGRESS' : widget.status;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitBootstrapCurrentYear();
      _requestSummariesIfContextAvailable();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BootstrapCurrentYearBloc, BootstrapContextState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) => _requestSummariesIfContextAvailable(),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF4F8FF), Color(0xFFEFF5FF), Color(0xFFF7FAFF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -50,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 120,
              left: -40,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            RefreshIndicator(
              onRefresh: _requestSummariesIfContextAvailable,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppTheme.largePadding),
                child: BlocBuilder<BootstrapCurrentYearBloc, BootstrapContextState>(
                  builder: (context, bootstrapState) {
                    final academicYearId =
                        bootstrapState.bootstrap?.academicYear.id ?? '';
                    final schoolId = context.select(
                      (AuthBloc bloc) => bloc.state.user?.schoolId ?? '',
                    );
                    final hasBootstrapContext =
                        bootstrapState.status ==
                            BootstrapContextLoadStatus.success &&
                        academicYearId.isNotEmpty &&
                        schoolId.isNotEmpty;

                    if (bootstrapState.status ==
                            BootstrapContextLoadStatus.loading ||
                        bootstrapState.status ==
                            BootstrapContextLoadStatus.initial) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    if (!hasBootstrapContext) {
                      return BootstrapContextError(
                        onLogout: () => context.read<AuthBloc>().add(
                          const AuthLogoutRequested(),
                        ),
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SearchForm(
                          academicYearId: academicYearId,
                          status: _effectiveStatus,
                          showStatusFilter: widget.showStatusFilter,
                          onStatusChanged: (newStatus) {
                            setState(() => _effectiveStatus = newStatus);
                            _requestSummariesIfContextAvailable();
                          },
                        ),
                        const SizedBox(height: 12),
                        BlocBuilder<EnrollmentBloc, EnrollmentState>(
                          builder: (context, state) => PreRegistrationsInfoBar(
                            count: state.summariesTotalElements,
                            isLoading: _isLoading(state),
                            onRefresh: _requestSummariesIfContextAvailable,
                            statusLabel: widget.status,
                            showStatusBadge: widget.showStatusBadge,
                            currentPage: state.summariesPage,
                            totalPages: state.summariesTotalPages,
                            onPreviousPage: () => context.read<EnrollmentBloc>().add(
                              EnrollmentSummariesPageRequested(
                                page: state.summariesPage - 1,
                              ),
                            ),
                            onNextPage: () => context.read<EnrollmentBloc>().add(
                              EnrollmentSummariesPageRequested(
                                page: state.summariesPage + 1,
                              ),
                            ),
                            action: widget.action,
                          ),
                        ),
                        const SizedBox(height: 12),
                        BlocBuilder<EnrollmentBloc, EnrollmentState>(
                          builder: (context, state) => EnrollmentDataTable(
                            isLoading: _isLoading(state),
                            enrollments: state.summaries,
                            totalCount: state.summariesTotalElements,
                            onViewRequested: (summary) {
                              final intent = widget.intentFactory(summary);
                              context.push(
                                Uri(
                                  path:
                                      '${EnrollmentConstants.enrollmentDetailRoute}/${summary.enrollmentId}',
                                  queryParameters: intent.toQueryParameters(),
                                ).toString(),
                                extra: intent,
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestSummariesIfContextAvailable() async {
    if (!mounted) return;

    final now = DateTime.now();
    final lastRefreshAt = _lastRefreshAt;
    if (lastRefreshAt != null &&
        now.difference(lastRefreshAt) < _refreshCooldown) {
      return;
    }

    final bootstrapState = context.read<BootstrapCurrentYearBloc>().state;
    final academicYearId = bootstrapState.bootstrap?.academicYear.id ?? '';
    final schoolId = context.read<AuthBloc>().state.user?.schoolId ?? '';
    final enrollmentBloc = context.read<EnrollmentBloc>();
    final lastSummariesQuery = enrollmentBloc.state.lastSummariesQuery;
    final isSummariesLoading =
        enrollmentBloc.state.summariesStatus == EnrollmentLoadStatus.loading;

    if (bootstrapState.status != BootstrapContextLoadStatus.success ||
        academicYearId.isEmpty ||
        schoolId.isEmpty ||
        isSummariesLoading) {
      return;
    }

    _lastRefreshAt = now;

    if (lastSummariesQuery != null && lastSummariesQuery.status == _effectiveStatus) {
      enrollmentBloc.add(const EnrollmentSummariesRefreshRequested());
      return;
    }

    enrollmentBloc.add(
      EnrollmentSummariesRequested(
        status: _effectiveStatus,
        academicYearId: academicYearId,
        page: 0,
      ),
    );
  }

  void _emitBootstrapCurrentYear() {
    context.read<BootstrapCurrentYearBloc>().add(
      const BootstrapContextLocalRequested(
        key: AppConstants.bootstrapPayloadKey,
      ),
    );
  }

  bool _isLoading(EnrollmentState state) =>
      state.summariesStatus == EnrollmentLoadStatus.loading;
}
