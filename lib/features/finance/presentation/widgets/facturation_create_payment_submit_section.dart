import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
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
                  padding: const EdgeInsets.only(
                    bottom: AppDimensions.spacingM,
                  ),
                  child: Text(
                    l10n.facturationCreatePaymentNoAllocations,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.danger,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : const SizedBox.shrink(key: ValueKey('no_warning')),
        ),
        PrimaryButton(
          label: l10n.facturationCreatePaymentSubmitLabel,
          icon: Icons.check_circle_outline,
          isLoading: isLoading,
          onPressed: _canSubmit ? onSubmit : null,
        ),
      ],
    );
  }
}
