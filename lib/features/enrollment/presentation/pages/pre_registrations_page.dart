import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_data_table.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/pre_registrations_info_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form.dart';

class PreRegistrationsPage extends StatefulWidget {
  const PreRegistrationsPage({super.key});

  @override
  State<PreRegistrationsPage> createState() => _PreRegistrationsPageState();
}

class _PreRegistrationsPageState extends State<PreRegistrationsPage> {
  static const String _status = 'PRE_REGISTERED';
  static const Duration _refreshCooldown = Duration(milliseconds: 700);
  DateTime? _lastRefreshAt;
  late final WidgetsBindingObserver _lifecycleObserver =
      _PreRegistrationsLifecycleObserver(
        onResume: _requestSummariesIfContextAvailable,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestSummariesIfContextAvailable();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BootstrapBloc, BootstrapState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (context, state) => _requestSummariesIfContextAvailable(),
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF4F8FF), Color(0xFFEFF5FF), Color(0xFFF7FAFF)],
            ),
          ),
          child: Stack(
            children: [
              // ── Cercles décoratifs ────────────────────────────────
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
              // ── Contenu entièrement scrollable ───────────────────
              RefreshIndicator(
                onRefresh: _requestSummariesIfContextAvailable,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppTheme.largePadding),
                  child: BlocBuilder<BootstrapBloc, BootstrapState>(
                    builder: (context, bootstrapState) {
                      final academicYearId =
                          bootstrapState.bootstrap?.currentAcademicYear.id ??
                          '';
                      final schoolId = context.select(
                        (AuthBloc bloc) => bloc.state.user?.schoolId ?? '',
                      );
                      final hasBootstrapContext =
                          bootstrapState.status ==
                              BootstrapLoadStatus.success &&
                          academicYearId.isNotEmpty &&
                          schoolId.isNotEmpty;

                      if (bootstrapState.status ==
                              BootstrapLoadStatus.loading ||
                          bootstrapState.status ==
                              BootstrapLoadStatus.initial) {
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
                            status: _status,
                          ),
                          const SizedBox(height: 12),
                          BlocBuilder<EnrollmentBloc, EnrollmentState>(
                            builder: (context, state) =>
                                PreRegistrationsInfoBar(
                                  count: state.summaries.length,
                                  isLoading: _isLoading(state),
                                  onRefresh:
                                      _requestSummariesIfContextAvailable,
                                ),
                          ),
                          const SizedBox(height: 12),
                          BlocBuilder<EnrollmentBloc, EnrollmentState>(
                            builder: (context, state) => EnrollmentDataTable(
                              isLoading: _isLoading(state),
                              enrollments: state.summaries,
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

    final bootstrapState = context.read<BootstrapBloc>().state;
    final academicYearId =
        bootstrapState.bootstrap?.currentAcademicYear.id ?? '';
    final schoolId = context.read<AuthBloc>().state.user?.schoolId ?? '';
    final isSummariesLoading =
        context.read<EnrollmentBloc>().state.summariesStatus ==
        EnrollmentLoadStatus.loading;

    if (bootstrapState.status != BootstrapLoadStatus.success ||
        academicYearId.isEmpty ||
        schoolId.isEmpty ||
        isSummariesLoading) {
      return;
    }

    _lastRefreshAt = now;

    context.read<EnrollmentBloc>().add(
      EnrollmentSummariesRequested(
        status: _status,
        academicYearId: academicYearId,
      ),
    );
  }

  bool _isLoading(EnrollmentState state) =>
      state.summariesStatus == EnrollmentLoadStatus.loading;
}

class _PreRegistrationsLifecycleObserver with WidgetsBindingObserver {
  final VoidCallback onResume;

  const _PreRegistrationsLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
