import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/constants/enrollment_page_layout.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';

class EnrollmentCurrentYearBootstrapBuilder extends StatefulWidget {
  final String status;

  /// Filtre de type propre à la page (ex. `PRE_ENROLLMENT` pour la page
  /// Pré-inscriptions) : porté sur le chargement initial par statut pour ne pas
  /// mélanger les dossiers de réinscription (même statut PRE_REGISTERED). Null
  /// = pas de filtre par type.
  final String? enrollmentType;
  final Widget Function(BuildContext context, EnrollmentScreenContext ctx)
  onReady;

  const EnrollmentCurrentYearBootstrapBuilder({
    super.key,
    required this.status,
    this.enrollmentType,
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
  void didUpdateWidget(
    covariant EnrollmentCurrentYearBootstrapBuilder oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status ||
        oldWidget.enrollmentType != widget.enrollmentType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _requestSummariesIfContextAvailable();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AcademicYearContextBloc, AcademicYearContextState>(
      listenWhen: (previous, current) => previous.status != current.status,
      listener: (_, _) => _requestSummariesIfContextAvailable(),
      child: BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
        builder: (context, academicYearState) {
          final academicYearId =
              academicYearState.context?.academicYear.id ?? '';
          final schoolId = context.select(
            (AuthBloc bloc) => bloc.state.user?.schoolId ?? '',
          );
          final hasBootstrapContext =
              academicYearState.status ==
                  AcademicYearContextLoadStatus.success &&
              academicYearId.isNotEmpty &&
              schoolId.isNotEmpty;

          if (academicYearState.status ==
                  AcademicYearContextLoadStatus.loading ||
              academicYearState.status ==
                  AcademicYearContextLoadStatus.initial) {
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
            (EnrollmentLocalListBloc bloc) =>
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

    final academicYearState = context.read<AcademicYearContextBloc>().state;
    final academicYearId = academicYearState.context?.academicYear.id ?? '';
    final schoolId = context.read<AuthBloc>().state.user?.schoolId ?? '';
    final listBloc = context.read<EnrollmentLocalListBloc>();
    final lastSummariesQuery = listBloc.state.lastSummariesQuery;
    final isSummariesLoading =
        listBloc.state.summariesStatus == EnrollmentLoadStatus.loading;

    if (academicYearState.status != AcademicYearContextLoadStatus.success ||
        academicYearId.isEmpty ||
        schoolId.isEmpty ||
        isSummariesLoading) {
      return;
    }

    _lastRefreshAt = now;

    if (lastSummariesQuery != null &&
        lastSummariesQuery.status == widget.status &&
        lastSummariesQuery.enrollmentType == widget.enrollmentType) {
      listBloc.add(const LocalListRefreshRequested());
      return;
    }

    listBloc.add(
      LocalListByStatusRequested(
        status: widget.status,
        academicYearId: academicYearId,
        enrollmentType: widget.enrollmentType,
        page: 0,
      ),
    );
  }

  void _emitBootstrapCurrentYear() {
    context.read<AcademicYearContextBloc>().add(
      const AcademicYearContextRequested(),
    );
  }
}
