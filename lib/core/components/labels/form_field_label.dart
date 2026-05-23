import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

class FormFieldLabel extends StatefulWidget {
  final String label;
  final bool requiredField;
  final String helpMessage;
  final Color? labelColor;

  const FormFieldLabel({
    super.key,
    required this.label,
    this.requiredField = false,
    this.helpMessage = '',
    this.labelColor,
  });

  @override
  State<FormFieldLabel> createState() => _FormFieldLabelState();
}

class _FormFieldLabelState extends State<FormFieldLabel> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
                text: widget.label,
                style: AppTypography.labelFormMedium.copyWith(
                    fontWeight: FontWeight.w700,
                color: widget.labelColor ?? AppColors.textSecondary,
              ),
              children: [
                if (widget.requiredField)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppColors.error),
                  ),
              ],
            ),
          ),
        ),
        if (widget.helpMessage.isNotEmpty)
          Tooltip(
            message: widget.helpMessage,
            showDuration: AppMotion.tooltipShowDuration,
            triggerMode: TooltipTriggerMode.tap,
            preferBelow: true,
            decoration: BoxDecoration(
              color: AppColors.textPrimary.withValues(alpha: 0.9),
              borderRadius: AppRadius.brSm,
            ),
            textStyle: const TextStyle(color: AppColors.textOnDark, fontSize: 12),
            child: const MouseRegion(
              cursor: SystemMouseCursors.help,
              child: SizedBox(
                width: AppDimensions.minTouchTarget,
                height: AppDimensions.minTouchTarget,
                child: Center(
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
