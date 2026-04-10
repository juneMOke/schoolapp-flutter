import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';

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
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: widget.labelColor ?? AppTheme.textPrimaryColor,
              ),
              children: [
                if (widget.requiredField)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Color(0xFFEF4444)),
                  ),
              ],
            ),
          ),
        ),
        if (widget.helpMessage.isNotEmpty)
          Tooltip(
            message: widget.helpMessage,
            showDuration: const Duration(seconds: 3),
            preferBelow: true,
            decoration: BoxDecoration(
              color: AppTheme.textPrimaryColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(color: Colors.white, fontSize: 12),
            child: const MouseRegion(
              cursor: SystemMouseCursors.help,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.help_outline_rounded,
                  size: 16,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
