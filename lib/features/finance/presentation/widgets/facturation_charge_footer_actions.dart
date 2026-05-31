import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// Footer sticky pour détail charge : bouton secondaire unique "Imprimer le relevé".
class FacturationChargeFooterActions extends StatelessWidget {
  final String printLabel;
  final VoidCallback onPrintStatements;

  const FacturationChargeFooterActions({
    super.key,
    required this.printLabel,
    required this.onPrintStatements,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 420;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceRaised,
            border: Border(
              top: BorderSide(
                color: AppColors.borderStrong.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.spacingM),
              child: SecondaryButton(
                label: printLabel,
                icon: compact ? null : Icons.print_outlined,
                onPressed: onPrintStatements,
              ),
            ),
          ),
        );
      },
    );
  }
}
