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
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_content_shell.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_info_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_state_widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_read_only_banner.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 18,
        leading: _BackButton(),
        title: EnrollmentDetailAppBarTitle(
          enrollmentId: _effectiveIntent.enrollmentId,
        ),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: BlocListener<EnrollmentBloc, EnrollmentState>(
        listenWhen: (previous, current) =>
            previous.createStatus != current.createStatus &&
            current.createStatus == EnrollmentLoadStatus.success,
        listener: (context, state) {
          final createdEnrollmentSummary = state.createdEnrollmentSummary;
          final nextIntent = _policy.resolveEffectiveIntent(
            baseIntent: _effectiveIntent,
            createdEnrollmentSummary: createdEnrollmentSummary,
          );

          if (nextIntent != _effectiveIntent) {
            setState(() => _effectiveIntent = nextIntent);
          }

          _policy.requestLoad(
            context.read<EnrollmentBloc>(),
            nextIntent,
            silent: true,
          );
          context.read<EnrollmentBloc>().add(
            const EnrollmentSummariesRefreshRequested(),
          );
          if (widget.intent != nextIntent) {
            context.replace(nextIntent.toLocation(), extra: nextIntent);
          }
          context.read<EnrollmentBloc>().add(
            const EnrollmentCreateResultConsumed(),
          );
        },
        child: BlocBuilder<EnrollmentBloc, EnrollmentState>(
          buildWhen: (previous, current) =>
              _policy.loadStatus(previous) != _policy.loadStatus(current) ||
              _policy.detail(previous) != _policy.detail(current) ||
              previous.errorMessage != current.errorMessage,
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
            final isFirstRegistrationView =
                _effectiveIntent.origin ==
                EnrollmentDetailOrigin.firstRegistration;
            final accessMode = switch (enrollment.status) {
              EnrollmentStatus.completed => EnrollmentDetailAccessMode.readOnly,
              EnrollmentStatus.inProgress =>
                EnrollmentDetailAccessMode.editable,
              _ => null,
            };
            final showAccessBanner =
                isFirstRegistrationView && accessMode != null;

            return EnrollmentDetailContentShell(
              infoBar: EnrollmentDetailInfoBar(
                enrollmentCode: enrollment.enrollmentCode,
                status: enrollment.status,
              ),
              child: Column(
                children: [
                  if (showAccessBanner) ...[
                    EnrollmentReadOnlyBanner(mode: accessMode),
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
}

// ─── Bouton retour ────────────────────────────────────────────────────────────

class _BackButton extends StatefulWidget {
  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: 'Retour',
          preferBelow: false,
          child: GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _hovered
                    ? AppTheme.primaryColor.withValues(alpha: 0.10)
                    : AppTheme.primaryColor.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _hovered
                      ? AppTheme.primaryColor.withValues(alpha: 0.30)
                      : AppTheme.primaryColor.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: _hovered
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
