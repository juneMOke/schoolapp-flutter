import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
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
    this.spacing = AppDimensions.spacingM,
  });
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canGoToPrevious = currentPage > 1 && !isLoading;
    final canGoToNext = currentPage < totalPages && !isLoading;
    final defaultLabel =
        pageLabel?.call(currentPage, totalPages) ??
        'Page $currentPage / $totalPages';
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingM,
        vertical: AppDimensions.spacingS,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: spacing,
        children: [
          _PaginationButton(
            onPressed: canGoToPrevious ? onPrevious : null,
            icon: Icons.chevron_left_rounded,
            tooltip: l10n.previous,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.bleuArdoise.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              defaultLabel,
              style: AppTextStyles.pageTitle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.bleuArdoise,
              ),
            ),
          ),
          _PaginationButton(
            onPressed: canGoToNext ? onNext : null,
            icon: Icons.chevron_right_rounded,
            tooltip: l10n.next,
          ),
        ],
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
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => isEnabled ? setState(() => _hovered = true) : null,
        onExit: (_) => isEnabled ? setState(() => _hovered = false) : null,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _hovered && isEnabled
                ? AppColors.bleuArdoise.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isEnabled
                  ? (_hovered ? AppColors.bleuArdoise : AppColors.border)
                  : AppColors.stateDisabled,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onPressed,
              child: Icon(
                widget.icon,
                size: 20,
                color: isEnabled
                    ? (_hovered
                          ? AppColors.bleuArdoise
                          : AppColors.textSecondary)
                    : AppColors.stateDisabled,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
