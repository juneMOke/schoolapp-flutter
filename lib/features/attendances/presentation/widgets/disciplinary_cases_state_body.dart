import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_summary.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_create_cta.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_cases_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum DisciplinaryCasesBodyStatus {
  loading,
  empty,
  error,
  success,
}

class DisciplinaryCasesStateBody extends StatelessWidget {
  final DisciplinaryCasesBodyStatus status;
  final List<DisciplinaryCaseSummary> cases;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final void Function(DisciplinaryCaseSummary) onViewCase;
  /// Callback optionnel affiché dans l'état vide pour inviter à créer un cas.
  final VoidCallback? onCreateCase;

  const DisciplinaryCasesStateBody({
    super.key,
    required this.status,
    required this.cases,
    this.errorMessage,
    this.onRetry,
    required this.onViewCase,
    this.onCreateCase,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final child = switch (status) {
      DisciplinaryCasesBodyStatus.loading => _buildLoadingContent(l10n),
      DisciplinaryCasesBodyStatus.empty => _buildEmptyContent(l10n),
      DisciplinaryCasesBodyStatus.error => _buildErrorContent(l10n),
      DisciplinaryCasesBodyStatus.success => DisciplinaryCasesTable(
        cases: cases,
        onViewCase: onViewCase,
      ),
    };

    return AnimatedSwitcher(
      duration: AppMotion.standard,
      switchInCurve: AppMotion.outCurve,
      switchOutCurve: AppMotion.inCurve,
      child: KeyedSubtree(
        key: ValueKey('${status.name}-${cases.length}-${errorMessage ?? ''}'),
        child: child,
      ),
    );
  }

  Widget _buildLoadingContent(AppLocalizations l10n) {
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
                        width: AppDimensions.minTouchTarget +
                            AppDimensions.spacingM,
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
              // Loading skeletons
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.fromLTRB(
                    AppDimensions.spacingM,
                    isCompact ? AppDimensions.spacingM : AppDimensions.spacingS,
                    AppDimensions.spacingM,
                    AppDimensions.spacingM,
                  ),
                  itemCount: 3,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppDimensions.spacingS),
                  itemBuilder: (_, index) => _SkeletonCaseRow(
                    delay: Duration(milliseconds: 100 * index),
                    isCompact: isCompact,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyContent(AppLocalizations l10n) {
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inbox_outlined,
                  size: 40,
                  color: AppColors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppDimensions.spacingM),
              Text(
                l10n.disciplinaryCasesEmptyMessage,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (onCreateCase != null) ...[
                const SizedBox(height: AppDimensions.spacingL),
                DisciplinaryCaseCreateCta(
                  onPressed: onCreateCase!,
                  label: l10n.disciplinaryCaseCreateAction,
                  subtitle: l10n.disciplinaryCaseCreateCtaSubtitle,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorContent(AppLocalizations l10n) {
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                errorMessage ?? l10n.disciplinaryCasesUnknownError,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppDimensions.spacingM),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.refresh),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader animé pour les lignes en cours de chargement
class _SkeletonCaseRow extends StatefulWidget {
  final Duration delay;
  final bool isCompact;

  const _SkeletonCaseRow({
    required this.delay,
    required this.isCompact,
  });

  @override
  State<_SkeletonCaseRow> createState() => _SkeletonCaseRowState();
}

class _SkeletonCaseRowState extends State<_SkeletonCaseRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerAnimation =
        Tween<double>(begin: -1.0, end: 2.0).animate(_shimmerController);

    Future.delayed(widget.delay, () {
      if (mounted) {
        _shimmerController.repeat();
      }
    });
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.disciplinaryDetailInfoSurface,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: AppColors.border),
      ),
      child: widget.isCompact
          ? _buildCompactSkeleton()
          : _buildDesktopSkeleton(),
    );
  }

  Widget _buildCompactSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ShimmerBox(
          shimmerAnimation: _shimmerAnimation,
          height: 20,
          width: double.infinity,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        _ShimmerBox(
          shimmerAnimation: _shimmerAnimation,
          height: 16,
          width: 120,
        ),
        const SizedBox(height: AppDimensions.spacingS),
        Align(
          alignment: Alignment.centerRight,
          child: _ShimmerBox(
            shimmerAnimation: _shimmerAnimation,
            height: 40,
            width: 40,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSkeleton() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _ShimmerBox(
            shimmerAnimation: _shimmerAnimation,
            height: 20,
            width: double.infinity,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          flex: 3,
          child: _ShimmerBox(
            shimmerAnimation: _shimmerAnimation,
            height: 20,
            width: double.infinity,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
        _ShimmerBox(
          shimmerAnimation: _shimmerAnimation,
          height: 40,
          width: 100,
        ),
      ],
    );
  }
}

/// Box avec effet shimmer (chargement)
class _ShimmerBox extends StatelessWidget {
  final Animation<double> shimmerAnimation;
  final double height;
  final double width;

  const _ShimmerBox({
    required this.shimmerAnimation,
    required this.height,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerAnimation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [
                shimmerAnimation.value - 1,
                shimmerAnimation.value,
                shimmerAnimation.value + 1,
              ],
              colors: [
                AppColors.border,
                AppColors.textSecondary.withValues(alpha: 0.1),
                AppColors.border,
              ],
            ),
          ),
        );
      },
    );
  }
}
