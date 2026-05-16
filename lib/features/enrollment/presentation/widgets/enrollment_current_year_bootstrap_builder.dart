import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/constants/enrollment_page_layout.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';

class EnrollmentCurrentYearBootstrapBuilder extends StatefulWidget {
  final String status;
  final Widget Function(BuildContext context, EnrollmentScreenContext ctx) onReady;

  const EnrollmentCurrentYearBootstrapBuilder({
    super.key,
    required this.status,
    required this.onReady,
  });

  @override
  State<EnrollmentCurrentYearBootstrapBuilder> createState() =>
      _EnrollmentCurrentYearBootstrapBuilderState();
}

class _EnrollmentCurrentYearBootstrapBuilderState
    extends State<EnrollmentCurrentYearBootstrapBuilder> {
  DateTime? _lastRefreshAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _emitBootstrapCurrentYear();
      _requestSummariesIfContextAvailable();
    });
  }

  @override
  void didUpdateWidget(covariant EnrollmentCurrentYearBootstrapBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _requestSummariesIfContextAvailable();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<BootstrapCurrentYearBloc, BootstrapContextState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (_, __) => _requestSummariesIfContextAvailable(),
      child: BlocBuilder<BootstrapCurrentYearBloc, BootstrapContextState>(
        builder: (context, bootstrapState) {
          final academicYearId = bootstrapState.bootstrap?.academicYear.id ?? '';
          final schoolId = context.select(
            (AuthBloc bloc) => bloc.state.user?.schoolId ?? '',
          );
          final hasBootstrapContext =
              bootstrapState.status == BootstrapContextLoadStatus.success &&
              academicYearId.isNotEmpty &&
              schoolId.isNotEmpty;

          if (bootstrapState.status == BootstrapContextLoadStatus.loading ||
              bootstrapState.status == BootstrapContextLoadStatus.initial) {
            return const Center(
              child: Padding(
                padding: EnrollmentPageLayout.loadingPadding,
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (!hasBootstrapContext) {
            return BootstrapContextError(
              onLogout: () =>
                  context.read<AuthBloc>().add(const AuthLogoutRequested()),
            );
          }

          final isLoading = context.select(
            (EnrollmentBloc bloc) =>
                bloc.state.summariesStatus == EnrollmentLoadStatus.loading,
          );

          return widget.onReady(
            context,
            EnrollmentScreenContext(
              schoolId: schoolId,
              academicYearId: academicYearId,
              isLoading: isLoading,
              onRefreshRequested: _requestSummariesIfContextAvailable,
            ),
          );
        },
      ),
    );
  }

  Future<void> _requestSummariesIfContextAvailable() async {
    if (!mounted) return;

    final now = DateTime.now();
    final lastRefreshAt = _lastRefreshAt;
    if (lastRefreshAt != null &&
        now.difference(lastRefreshAt) < AppMotion.refreshCooldown) {
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

    if (lastSummariesQuery != null &&
        lastSummariesQuery.status == widget.status) {
      enrollmentBloc.add(const EnrollmentSummariesRefreshRequested());
      return;
    }

    enrollmentBloc.add(
      EnrollmentSummariesRequested(
        status: widget.status,
        academicYearId: academicYearId,
        page: 0,
      ),
    );
  }

  void _emitBootstrapCurrentYear() {
    context.read<BootstrapCurrentYearBloc>().add(
      const BootstrapContextLocalRequested(key: AppConstants.bootstrapPayloadKey),
    );
  }
}
