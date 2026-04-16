import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_previous_year_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_app_bar_title.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_content_shell.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_info_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_state_widgets.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper.dart';

class EnrollmentDetailPage extends StatefulWidget {
  final EnrollmentDetailIntent intent;

  const EnrollmentDetailPage({super.key, required this.intent});

  @override
  State<EnrollmentDetailPage> createState() => _EnrollmentDetailPageState();
}

class _EnrollmentDetailPageState extends State<EnrollmentDetailPage> {
  late EnrollmentDetailPolicy _policy;

  @override
  void initState() {
    super.initState();
    _policy = EnrollmentDetailPolicyResolver.fromOrigin(widget.intent.origin);
    _requestBootstrapContexts();
    _requestDetail();
  }

  @override
  void didUpdateWidget(covariant EnrollmentDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intent.origin != widget.intent.origin) {
      _policy = EnrollmentDetailPolicyResolver.fromOrigin(widget.intent.origin);
      _requestBootstrapContexts();
    }
    if (oldWidget.intent != widget.intent) {
      _requestBootstrapContexts();
      _requestDetail();
    }
  }

  void _requestDetail() {
    _policy.requestLoad(context.read<EnrollmentBloc>(), widget.intent);
  }

  void _requestBootstrapContexts() {
    if (_policy.requiresCurrentYearBootstrap(widget.intent)) {
      context.read<BootstrapCurrentYearBloc>().add(
        const BootstrapContextLocalRequested(
          key: AppConstants.bootstrapPayloadKey,
        ),
      );
    }

    if (_policy.requiresPreviousYearBootstrap(widget.intent)) {
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
          enrollmentId: widget.intent.enrollmentId,
        ),
        backgroundColor: AppTheme.surfaceColor,
      ),
      body: BlocBuilder<EnrollmentBloc, EnrollmentState>(
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

          return EnrollmentDetailContentShell(
            infoBar: EnrollmentDetailInfoBar(
              enrollmentCode: enrollment.enrollmentCode,
              status: enrollment.status,
            ),
            child: EnrollmentStepper(
              enrollmentDetail: detail,
              detailIntent: widget.intent,
              detailPolicy: _policy,
            ),
          );
        },
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
