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
    final topPadding = isCompact ? AppDimensions.spacingM : AppDimensions.spacingS;

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
                  flex: 3,
                  child: Text(
                    l10n.disciplinaryCasesTableStatusColumn,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppDimensions.spacingM),
                SizedBox(
                  width: AppDimensions.minTouchTarget + AppDimensions.spacingM,
                  child: Text(
                    l10n.disciplinaryCasesTableActionColumn,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
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
            separatorBuilder: (_, _) => const SizedBox(height: AppDimensions.spacingS),
            itemBuilder: (context, index) {
              final caseData = cases[index];
              return _AnimatedCaseRow(
                delay: Duration(milliseconds: 50 * index),
                child: Container(
                  padding: const EdgeInsets.all(AppDimensions.spacingM),
                  decoration: BoxDecoration(
                    color: AppColors.disciplinaryDetailInfoSurface,
                    borderRadius: BorderRadius.circular(AppDimensions.spacingM),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: isCompact
                      ? _buildCompactRow(caseData, l10n)
                      : _buildDesktopRow(caseData, l10n),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCompactRow(
    DisciplinaryCaseSummary caseData,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          caseData.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppDimensions.spacingS),
        _buildStatusBadge(caseData, l10n),
        const SizedBox(height: AppDimensions.spacingS),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            style: IconButton.styleFrom(
              minimumSize: const Size(
                AppDimensions.minTouchTarget,
                AppDimensions.minTouchTarget,
              ),
              backgroundColor: AppColors.disciplinaryDetailAccentSoft,
              foregroundColor: AppColors.disciplinaryDetailAccent,
              side: BorderSide(
                color: AppColors.disciplinaryDetailAccent.withValues(alpha: 0.2),
              ),
            ),
            icon: const Icon(Icons.visibility_outlined),
            tooltip: l10n.disciplinaryCaseViewLabel,
            onPressed: () => onViewCase(caseData),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopRow(
    DisciplinaryCaseSummary caseData,
    AppLocalizations l10n,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            caseData.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(flex: 3, child: _buildStatusBadge(caseData, l10n)),
        const SizedBox(width: AppDimensions.spacingM),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(
              AppDimensions.minTouchTarget,
              AppDimensions.minTouchTarget,
            ),
            foregroundColor: AppColors.disciplinaryDetailAccent,
            backgroundColor: AppColors.disciplinaryDetailAccentSoft,
            side: BorderSide(
              color: AppColors.disciplinaryDetailAccent.withValues(alpha: 0.2),
            ),
          ),
          onPressed: () => onViewCase(caseData),
          icon: const Icon(Icons.visibility_outlined),
          label: Text(l10n.disciplinaryCaseViewLabel),
        ),
      ],
    );
  }

   Widget _buildStatusBadge(
     DisciplinaryCaseSummary caseData,
     AppLocalizations l10n,
   ) {
     final statusColor = caseData.status.getColor();
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
       child: Text(
         caseData.status.getDisplayName(l10n),
         style: AppTextStyles.caption.copyWith(
           color: statusColor,
           fontWeight: FontWeight.w700,
         ),
       ),
     );
   }
 }

 /// Wrapper animé pour les lignes de cas (fade-in + slide)
 class _AnimatedCaseRow extends StatefulWidget {
   final Widget child;
   final Duration delay;

   const _AnimatedCaseRow({
     required this.child,
     required this.delay,
   });

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

     _slideAnimation = Tween<Offset>(
       begin: const Offset(0.0, 0.1),
       end: Offset.zero,
     ).animate(
       CurvedAnimation(parent: _animationController, curve: AppMotion.outCurve),
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
       child: SlideTransition(
         position: _slideAnimation,
         child: widget.child,
       ),
     );
   }
 }
