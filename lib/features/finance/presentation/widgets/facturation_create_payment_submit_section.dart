import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_motion.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Bouton de validation du paiement avec état chargement + message si aucune allocation.
class FacturationCreatePaymentSubmitSection extends StatelessWidget {
  final bool hasAllocations;
  final bool isLoading;
  final bool isSubmitted;
  final VoidCallback onSubmit;

  const FacturationCreatePaymentSubmitSection({
    super.key,
    required this.hasAllocations,
    required this.isLoading,
    required this.isSubmitted,
    required this.onSubmit,
  });

  bool get _canSubmit => hasAllocations && !isLoading && !isSubmitted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AnimatedSwitcher(
          duration: FinanceMotion.medium,
          child: (!hasAllocations && !isSubmitted)
              ? Padding(
                  key: const ValueKey('no_allocations_warning'),
                  padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
                  child: Text(
                    l10n.facturationCreatePaymentNoAllocations,
                    style: AppTextStyles.caption.copyWith(color: AppColors.danger),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('no_warning')),
        ),
        _SubmitButton(
          label: l10n.facturationCreatePaymentSubmitLabel,
          isLoading: isLoading,
          canSubmit: _canSubmit,
          onSubmit: onSubmit,
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final bool canSubmit;
  final VoidCallback onSubmit;

  const _SubmitButton({
    required this.label,
    required this.isLoading,
    required this.canSubmit,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: FinanceMotion.medium,
      curve: FinanceMotion.gentleOut,
      decoration: BoxDecoration(
        gradient: canSubmit
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.financeDetailPaymentsAccentLight,
                  AppColors.financeDetailPaymentsAccent,
                ],
              )
            : null,
        color: canSubmit ? null : AppColors.financeDetailMutedSurface,
        borderRadius: BorderRadius.circular(AppDimensions.spacingXL),
        boxShadow: canSubmit
            ? [
                BoxShadow(
                  color: AppColors.financeDetailPaymentsAccent.withValues(
                    alpha: 0.35,
                  ),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: canSubmit ? onSubmit : null,
          borderRadius: BorderRadius.circular(AppDimensions.spacingXL),
          splashColor: AppColors.surface.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading) ...[
                  const SizedBox(
                    width: AppDimensions.detailMiniIconSize,
                    height: AppDimensions.detailMiniIconSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  ),
                ] else ...[
                  Icon(
                    Icons.check_circle_outline,
                    color: canSubmit ? AppColors.surface : AppColors.textSecondary,
                    size: AppDimensions.detailMiniIconSize,
                  ),
                  const SizedBox(width: AppDimensions.spacingS),
                  Text(
                    label,
                    style: AppTextStyles.action.copyWith(
                      color:
                          canSubmit ? AppColors.surface : AppColors.textSecondary,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
