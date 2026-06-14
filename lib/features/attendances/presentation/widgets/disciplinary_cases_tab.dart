import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_severity.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_cases_state_body.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class DisciplinaryCasesTab extends StatelessWidget {
  final String studentId;
  final String academicYearId;

  /// Callback déclenché depuis l'en-tête / l'état vide pour créer un cas.
  final VoidCallback? onCreateCase;

  const DisciplinaryCasesTab({
    super.key,
    required this.studentId,
    required this.academicYearId,
    this.onCreateCase,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DisciplinaryCaseBloc, DisciplinaryCaseState>(
      buildWhen: (prev, curr) =>
          prev.listStatus != curr.listStatus ||
          prev.listErrorType != curr.listErrorType ||
          prev.cases != curr.cases,
      builder: (context, state) {
        final total = state.cases.length;
        final open = state.cases
            .where(
              (c) =>
                  c.status == DisciplinaryCaseStatus.open ||
                  c.status == DisciplinaryCaseStatus.inProgress,
            )
            .length;
        final grave = state.cases
            .where((c) => c.severity == DisciplinarySeverity.serious)
            .length;

        final bodyStatus = switch (state.listStatus) {
          DisciplinaryCaseStatusState.loading =>
            DisciplinaryCasesBodyStatus.loading,
          DisciplinaryCaseStatusState.initial =>
            DisciplinaryCasesBodyStatus.loading,
          DisciplinaryCaseStatusState.failure =>
            DisciplinaryCasesBodyStatus.error,
          DisciplinaryCaseStatusState.success when state.cases.isEmpty =>
            DisciplinaryCasesBodyStatus.empty,
          DisciplinaryCaseStatusState.success =>
            DisciplinaryCasesBodyStatus.success,
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingL),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DisciplinaryCasesHeader(
                total: total,
                open: open,
                grave: grave,
                onCreateCase: onCreateCase,
              ),
              const SizedBox(height: AppDimensions.spacingM),
              DisciplinaryCasesStateBody(
                status: bodyStatus,
                cases: state.cases,
                errorType: state.listErrorType,
                onRetry: () => _retryList(context),
                onReconnect: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
                onContactAdmin: _contactAdmin,
                onCreateCase: onCreateCase,
                // Bouton d'avancement dormant : pas d'endpoint backend encore.
                onAdvance: (_) {},
              ),
            ],
          ),
        );
      },
    );
  }

  void _retryList(BuildContext context) {
    context.read<DisciplinaryCaseBloc>().add(
      DisciplinaryCaseListRequested(
        studentId: studentId,
        academicYearId: academicYearId,
      ),
    );
  }

  Future<void> _contactAdmin() async {
    await launchUrl(Uri(scheme: 'mailto', path: AppConstants.supportEmail));
  }
}

class _DisciplinaryCasesHeader extends StatelessWidget {
  final int total;
  final int open;
  final int grave;
  final VoidCallback? onCreateCase;

  const _DisciplinaryCasesHeader({
    required this.total,
    required this.open,
    required this.grave,
    required this.onCreateCase,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final summary = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingXS,
      children: [
        const Icon(
          Icons.assignment_outlined,
          size: 16,
          color: AppColors.textMuted,
        ),
        _Pill(
          label: l10n.disciplinaryCasesCountPill(total),
          background: AppColors.surfaceAlt,
          foreground: AppColors.textSecondary,
        ),
        if (open > 0)
          _Pill(
            label: l10n.disciplinaryCasesOpenPill(open),
            background: AppColors.error.withValues(alpha: 0.10),
            foreground: AppColors.error,
            icon: Icons.error_outline_rounded,
          ),
        if (grave > 0)
          _Pill(
            label: l10n.disciplinaryCasesGravePill(grave),
            background: AppColors.error.withValues(alpha: 0.10),
            foreground: AppColors.error,
            icon: Icons.warning_amber_rounded,
          ),
      ],
    );

    final button = PrimaryButton(
      label: l10n.disciplinaryCaseCreateAction,
      icon: Icons.add_rounded,
      fullWidth: false,
      onPressed: onCreateCase,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              summary,
              const SizedBox(height: AppDimensions.spacingS),
              button,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: summary),
            const SizedBox(width: AppDimensions.spacingM),
            button,
          ],
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: AppDimensions.spacingXS),
          ],
          Text(
            label,
            style: AppTextStyles.badge.copyWith(
              color: foreground,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
