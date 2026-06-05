import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Composant pagination générique réutilisable - UTILISE TOKENS DESIGN SYSTEM
class DataTablePaginationBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isLoading;
  final String Function(int current, int total)? pageLabel;
  final double spacing;
  const DataTablePaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    this.isLoading = false,
    this.pageLabel,
    this.spacing = AppDimensions.paginationGap,
  });
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canGoToPrevious = currentPage > 1 && !isLoading;
    final canGoToNext = currentPage < totalPages && !isLoading;
    final defaultLabel =
        pageLabel?.call(currentPage, totalPages) ??
        l10n.paginationPageIndicator(currentPage, totalPages);
    return Semantics(
      container: true,
      label: l10n.paginationNavigationLabel,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: spacing,
          children: [
            _PaginationButton(
              onPressed: canGoToPrevious ? onPrevious : null,
              icon: Icons.chevron_left_rounded,
              tooltip: l10n.previousPage,
            ),
            Semantics(
              container: true,
              liveRegion: true,
              label: defaultLabel,
              child: Container(
                height: AppDimensions.paginationButtonSize,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.paginationIndicatorHPadding,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bleuArdoise,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.paginationButtonRadius,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  defaultLabel,
                  style: AppTypography.labelMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.blancCasse,
                  ),
                ),
              ),
            ),
            _PaginationButton(
              onPressed: canGoToNext ? onNext : null,
              icon: Icons.chevron_right_rounded,
              tooltip: l10n.nextPage,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaginationButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  const _PaginationButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
  });
  @override
  State<_PaginationButton> createState() => _PaginationButtonState();
}

class _PaginationButtonState extends State<_PaginationButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.onPressed != null;
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.tooltip,
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          onEnter: (_) => isEnabled ? setState(() => _hovered = true) : null,
          onExit: (_) => isEnabled ? setState(() => _hovered = false) : null,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              borderRadius: BorderRadius.circular(
                AppDimensions.paginationButtonRadius,
              ),
              child: SizedBox.square(
                dimension: AppDimensions.paginationTapTarget,
                child: Center(
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    width: AppDimensions.paginationButtonSize,
                    height: AppDimensions.paginationButtonSize,
                    decoration: BoxDecoration(
                      color: _hovered && isEnabled
                          ? AppColors.bleuArdoise.withValues(alpha: 0.12)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.paginationButtonRadius,
                      ),
                      border: Border.all(
                        color: isEnabled
                            ? (_hovered
                                  ? AppColors.bleuArdoise
                                  : AppColors.border)
                            : AppColors.border,
                      ),
                    ),
                    child: Icon(
                      widget.icon,
                      size: AppDimensions.paginationIconSize,
                      color: isEnabled
                          ? (_hovered
                                ? AppColors.bleuArdoise
                                : AppColors.textSecondary)
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
