import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class DisciplinaryCasesTable extends StatelessWidget {
  final List<DisciplinaryCaseSummary> cases;
  final void Function(DisciplinaryCaseSummary) onViewCase;

  const DisciplinaryCasesTable({
    super.key,
    required this.cases,
    required this.onViewCase,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (cases.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Text(l10n.disciplinaryCasesEmptyMessage),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.sectionCardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.disciplinaryDetailShadow,
            blurRadius: AppDimensions.classesOrganisationShadowBlur,
            offset: Offset(0, AppDimensions.classesOrganisationShadowOffsetY),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact =
              constraints.maxWidth < AppDimensions.detailCompactBreakpoint;
          return _buildCasesList(context, l10n, isCompact: isCompact);
        },
      ),
    );
  }

  Widget _buildCasesList(
    BuildContext context,
    AppLocalizations l10n, {
    required bool isCompact,
  }) {
    final topPadding = isCompact
        ? AppDimensions.spacingM
        : AppDimensions.spacingS;

    return Column(
      children: [
        // Desktop header
        if (!isCompact)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.spacingM,
              AppDimensions.spacingM,
              AppDimensions.spacingM,
              AppDimensions.spacingS,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    l10n.disciplinaryCasesTableTitleColumn,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  flex: 4,
                  child: Text(
                    l10n.disciplinaryCasesTableStatusColumn,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        // Cases list
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              AppDimensions.spacingM,
              topPadding,
              AppDimensions.spacingM,
              AppDimensions.spacingM,
            ),
            itemCount: cases.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDimensions.spacingS),
            itemBuilder: (context, index) {
              final caseData = cases[index];
              return _AnimatedCaseRow(
                delay: Duration(milliseconds: 50 * index),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppDimensions.spacingM),
                    onTap: () => onViewCase(caseData),
                    child: Container(
                      padding: const EdgeInsets.all(AppDimensions.spacingM),
                      decoration: BoxDecoration(
                        color: AppColors.disciplinaryDetailInfoSurface,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.spacingM,
                        ),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: isCompact
                          ? _buildCompactRow(context, caseData, l10n)
                          : _buildDesktopRow(context, caseData, l10n),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactRow(
    BuildContext context,
    DisciplinaryCaseSummary caseData,
    AppLocalizations l10n,
  ) {
    final formattedDate = _formatCaseDate(context, caseData, l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caseData.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyStrong.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXS),
        Text(
          formattedDate,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Row(
          children: [
            Expanded(child: _buildStatusBadge(caseData, l10n)),
            const SizedBox(width: AppDimensions.spacingS),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopRow(
    BuildContext context,
    DisciplinaryCaseSummary caseData,
    AppLocalizations l10n,
  ) {
    final formattedDate = _formatCaseDate(context, caseData, l10n);

    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                caseData.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              Text(
                formattedDate,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          flex: 4,
          child: Row(
            children: [
              Expanded(child: _buildStatusBadge(caseData, l10n)),
              const SizedBox(width: AppDimensions.spacingS),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(
    DisciplinaryCaseSummary caseData,
    AppLocalizations l10n,
  ) {
    final statusColor = caseData.status.getColor();
    final statusIcon = switch (caseData.status) {
      DisciplinaryCaseStatus.open => Icons.folder_open_outlined,
      DisciplinaryCaseStatus.inProgress => Icons.timelapse_rounded,
      DisciplinaryCaseStatus.closed => Icons.check_circle_outline_rounded,
      DisciplinaryCaseStatus.unknown => Icons.help_outline_rounded,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: statusColor.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: AppDimensions.detailMiniIconSize,
            color: statusColor,
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Flexible(
            child: Text(
              caseData.status.getDisplayName(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCaseDate(
    BuildContext context,
    DisciplinaryCaseSummary caseData,
    AppLocalizations l10n,
  ) {
    final date = caseData.disciplinaryCaseDate;
    if (date == null) {
      return l10n.disciplinaryCasesDateUnavailable;
    }
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }
}

/// Wrapper animé pour les lignes de cas (fade-in + slide)
class _AnimatedCaseRow extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedCaseRow({required this.child, required this.delay});

  @override
  State<_AnimatedCaseRow> createState() => _AnimatedCaseRowState();
}

class _AnimatedCaseRowState extends State<_AnimatedCaseRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: AppMotion.standard,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: AppMotion.outCurve),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: AppMotion.outCurve,
          ),
        );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(position: _slideAnimation, child: widget.child),
    );
  }
}
