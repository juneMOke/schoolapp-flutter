import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

class SummaryNeutralLine extends StatelessWidget {
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  const SummaryNeutralLine({
    super.key,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (onRetry != null)
          SecondaryButton(
            label: retryLabel,
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
            fullWidth: false,
          ),
      ],
    );
  }
}
