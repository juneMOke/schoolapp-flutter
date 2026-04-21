import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_previous_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_status.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_origin.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_app_bar_title.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_back_button.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_content_shell.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_info_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_state_widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_read_only_banner.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class EnrollmentDetailPage extends StatefulWidget {
  final EnrollmentDetailIntent intent;

  const EnrollmentDetailPage({super.key, required this.intent});

  @override
  State<EnrollmentDetailPage> createState() => _EnrollmentDetailPageState();
}

class _EnrollmentDetailPageState extends State<EnrollmentDetailPage> {
  late EnrollmentDetailPolicy _policy;
  late EnrollmentDetailIntent _effectiveIntent;

  @override
  void initState() {
    super.initState();
    _policy = EnrollmentDetailPolicyResolver.fromIntent(widget.intent);
    _effectiveIntent = widget.intent;
    _requestBootstrapContexts();
    _requestDetail();
  }

  @override
  void didUpdateWidget(covariant EnrollmentDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intent != widget.intent) {
      final shouldRefreshFromRouter = widget.intent != _effectiveIntent;
      _policy = EnrollmentDetailPolicyResolver.fromIntent(widget.intent);
      _effectiveIntent = widget.intent;
      if (shouldRefreshFromRouter) {
        _requestBootstrapContexts();
        _requestDetail();
      }
    }
  }

  void _requestDetail() {
    _policy.requestLoad(context.read<EnrollmentBloc>(), _effectiveIntent);
  }

  void _requestBootstrapContexts() {
    if (_policy.requiresCurrentYearBootstrap(_effectiveIntent)) {
      context.read<BootstrapCurrentYearBloc>().add(
        const BootstrapContextLocalRequested(
          key: AppConstants.bootstrapPayloadKey,
        ),
      );
    }

    if (_policy.requiresPreviousYearBootstrap(_effectiveIntent)) {
      context.read<BootstrapPreviousYearBloc>().add(
        BootstrapContextLocalRequested(
          key: AppConstants.bootstrapPreviousYearPayloadKey,
        ),
      );
    }
  }

  /// Handle side effects after a successful enrollment creation:
  /// resolve next intent, refresh detail/summaries, sync route, then consume result.
  void _onEnrollmentCreated(BuildContext context, EnrollmentState state) {
    final createdEnrollmentSummary = state.createdEnrollmentSummary;
    final nextIntent = _policy.resolveEffectiveIntent(
      baseIntent: _effectiveIntent,
      createdEnrollmentSummary: createdEnrollmentSummary,
    );

    if (nextIntent != _effectiveIntent) {
      setState(() => _effectiveIntent = nextIntent);
    }

    final enrollmentBloc = context.read<EnrollmentBloc>();
    _policy.requestLoad(enrollmentBloc, nextIntent, silent: true);
    enrollmentBloc.add(const EnrollmentSummariesRefreshRequested());

    if (widget.intent != nextIntent) {
      context.replace(nextIntent.toLocation(), extra: nextIntent);
    }

    enrollmentBloc.add(const EnrollmentCreateResultConsumed());
  }

  /// Resolve detail access mode from enrollment status for first-registration flow.
  EnrollmentDetailAccessMode? _resolveAccessMode(EnrollmentStatus status) {
    return switch (status) {
      EnrollmentStatus.completed => EnrollmentDetailAccessMode.readOnly,
      EnrollmentStatus.inProgress => EnrollmentDetailAccessMode.editable,
      _ => null,
    };
  }

  /// Show access banner only in first-registration view when an access mode exists.
  bool _shouldShowAccessBanner({
    required EnrollmentDetailOrigin origin,
    required EnrollmentDetailAccessMode? accessMode,
  }) {
    return origin == EnrollmentDetailOrigin.firstRegistration &&
        accessMode != null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 18,
        leading: const EnrollmentDetailBackButton(),
        title: BlocSelector<EnrollmentBloc, EnrollmentState, String>(
          selector: (state) {
            final detail = _policy.detail(state);
            if (detail == null) {
              return '';
            }

            return [
              detail.studentDetail.firstName,
              detail.studentDetail.lastName,
              detail.studentDetail.surname,
            ].where((part) => part.trim().isNotEmpty).join(' ');
          },
          builder: (context, studentDisplayName) {
            return EnrollmentDetailAppBarTitle(
              titleLabel: l10n.enrollmentDetailTitle,
              titleValue: studentDisplayName.isNotEmpty
                  ? studentDisplayName
                  : l10n.enrollmentUnknownStudent,
            );
          },
        ),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: BlocListener<EnrollmentBloc, EnrollmentState>(
        listenWhen: _isEnrollmentCreated,
        listener: _onEnrollmentCreated,
        child: BlocBuilder<EnrollmentBloc, EnrollmentState>(
          buildWhen: _shouldRebuildEnrollmentDetail,
          builder: (context, state) {
            final loadStatus = _policy.loadStatus(state);
            final detail = _policy.detail(state);

            if (loadStatus == EnrollmentLoadStatus.loading) {
              return const EnrollmentDetailPageStateShell(
                child: EnrollmentDetailLoadingTemplate(),
              );
            }

            if (loadStatus == EnrollmentLoadStatus.failure) {
              return EnrollmentDetailPageStateShell(
                child: EnrollmentDetailErrorTemplate(
                  message:
                      state.errorMessage ??
                      'Erreur lors du chargement des détails.',
                  onRetry: _requestDetail,
                ),
              );
            }

            if (detail == null) {
              return const EnrollmentDetailPageStateShell(
                child: EnrollmentDetailEmptyTemplate(),
              );
            }

            final enrollment = detail.enrollmentDetail;
            final studentDisplayName = [
              detail.studentDetail.firstName,
              detail.studentDetail.lastName,
              detail.studentDetail.surname,
            ].where((part) => part.trim().isNotEmpty).join(' ');
            final accessMode = _resolveAccessMode(enrollment.status);
            final showAccessBanner = _shouldShowAccessBanner(
              origin: _effectiveIntent.origin,
              accessMode: accessMode,
            );

            return EnrollmentDetailContentShell(
              infoBar: EnrollmentDetailInfoBar(
                studentDisplayName: studentDisplayName.isNotEmpty
                    ? studentDisplayName
                    : enrollment.enrollmentCode,
                status: enrollment.status,
                isPreviousYearValidated: enrollment.validatedPreviousYear,
              ),
              child: Column(
                children: [
                  if (showAccessBanner) ...[
                    EnrollmentReadOnlyBanner(mode: accessMode!),
                    const SizedBox(height: 12),
                  ],
                  EnrollmentStepper(
                    enrollmentDetail: detail,
                    detailIntent: _effectiveIntent,
                    detailPolicy: _policy,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool _isEnrollmentCreated(EnrollmentState previous, EnrollmentState current) {
    return previous.createStatus != current.createStatus &&
        current.createStatus == EnrollmentLoadStatus.success;
  }

  /// Rebuild detail UI only when fields used by the screen rendering changed.
  bool _shouldRebuildEnrollmentDetail(
    EnrollmentState previous,
    EnrollmentState current,
  ) {
    return _policy.loadStatus(previous) != _policy.loadStatus(current) ||
        _policy.detail(previous) != _policy.detail(current) ||
        previous.errorMessage != current.errorMessage;
  }
}
