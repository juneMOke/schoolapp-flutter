import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_detail.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/disciplinary_case_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_dialog_shell.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class DisciplinaryCaseViewDialog extends StatefulWidget {
  final String caseId;
  final String studentId;
  final String title;

  const DisciplinaryCaseViewDialog({
    super.key,
    required this.caseId,
    required this.studentId,
    required this.title,
  });

  @override
  State<DisciplinaryCaseViewDialog> createState() =>
      _DisciplinaryCaseViewDialogState();
}

class _DisciplinaryCaseViewDialogState
    extends State<DisciplinaryCaseViewDialog> {
  @override
  void initState() {
    super.initState();
    context.read<DisciplinaryCaseBloc>().add(
      DisciplinaryCaseDetailRequested(caseId: widget.caseId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DisciplinaryCaseDialogShell(
      maxWidth: 600,
      child: BlocBuilder<DisciplinaryCaseBloc, DisciplinaryCaseState>(
        buildWhen: (prev, curr) =>
            prev.detailStatus != curr.detailStatus ||
            prev.selectedCase != curr.selectedCase,
        builder: (context, state) => AnimatedSwitcher(
          duration: AppMotion.standard,
          switchInCurve: AppMotion.outCurve,
          switchOutCurve: AppMotion.inCurve,
          child: switch (state.detailStatus) {
            DisciplinaryCaseStatusState.loading => _buildLoading(
              l10n,
              key: const ValueKey('loading'),
            ),
            DisciplinaryCaseStatusState.success => _buildContent(
              context,
              l10n,
              state,
              key: const ValueKey('success'),
            ),
            DisciplinaryCaseStatusState.failure => _buildError(
              context,
              l10n,
              key: const ValueKey('error'),
            ),
            DisciplinaryCaseStatusState.initial => const SizedBox.shrink(),
          },
        ),
      ),
    );
  }

  Widget _buildLoading(AppLocalizations l10n, {required ValueKey key}) {
    return KeyedSubtree(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.disciplinaryDetailAccentSoft,
                shape: BoxShape.circle,
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppDimensions.spacingS),
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation(
                    AppColors.disciplinaryDetailAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              l10n.disciplinaryCaseViewDialogLoadingMessage,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    DisciplinaryCaseState state, {
    required ValueKey key,
  }) {
    final caseDetail = state.selectedCase;
    if (caseDetail == null) {
      return _buildError(context, l10n, key: const ValueKey('null-error'));
    }

    return KeyedSubtree(
      key: key,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Header Hero with status
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingL,
              AppDimensions.spacingL,
              AppDimensions.spacingL,
              AppDimensions.spacingM,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.disciplinaryDetailAccentSoft,
                  AppColors.disciplinaryDetailAccentSoft.withValues(alpha: 0.7),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.sectionCardRadius),
                topRight: Radius.circular(AppDimensions.sectionCardRadius),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.disciplinaryCaseViewDialogTitle,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: AppDimensions.spacingXS),
                          Text(
                            caseDetail.title,
                            style: AppTextStyles.sectionTitle.copyWith(
                              color: AppColors.disciplinaryDetailAccent,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      color: AppColors.disciplinaryDetailAccent,
                      tooltip: l10n.cancel,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.spacingM),
                _buildStatusBadge(caseDetail, l10n),
              ],
            ),
          ),
          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status detail row
                  _buildDetailRow(
                    label: l10n.disciplinaryCaseViewDialogStatusField,
                    child: _buildStatusBadge(caseDetail, l10n),
                  ),
                  const SizedBox(height: AppDimensions.spacingL),
                  // Content section
                  Text(
                    l10n.disciplinaryCaseViewDialogContentField,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppDimensions.spacingM),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.spacingM,
                      ),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      caseDetail.content,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Semantics(
                  label: l10n.cancel,
                  button: true,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(
    BuildContext context,
    AppLocalizations l10n, {
    required ValueKey key,
  }) {
    return KeyedSubtree(
      key: key,
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 40,
                color: AppColors.danger.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Text(
              l10n.disciplinaryCaseViewDialogErrorMessage,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.spacingM),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        child,
      ],
    );
  }

  Widget _buildStatusBadge(
    DisciplinaryCaseDetail caseDetail,
    AppLocalizations l10n,
  ) {
    final statusColor = caseDetail.status.getColor();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDimensions.spacingL),
        border: Border.all(color: statusColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingS),
          Text(
            caseDetail.status.getDisplayName(l10n),
            style: AppTextStyles.caption.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
