import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';

class FormFieldLabel extends StatefulWidget {
  final String label;
  final bool requiredField;
  final String helpMessage;

  const FormFieldLabel({
    super.key,
    required this.label,
    this.requiredField = false,
    this.helpMessage = '',
  });

  @override
  State<FormFieldLabel> createState() => _FormFieldLabelState();
}

class _FormFieldLabelState extends State<FormFieldLabel> {
  final GlobalKey<TooltipState> _tooltipKey = GlobalKey<TooltipState>();

  void _showTooltip() => _tooltipKey.currentState?.ensureTooltipVisible();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              text: widget.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
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
            key: _tooltipKey,
            message: widget.helpMessage,
            showDuration: const Duration(seconds: 3),
            preferBelow: true,
            decoration: BoxDecoration(
              color: AppTheme.textPrimaryColor.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(color: Colors.white, fontSize: 12),
            child: MouseRegion(
              cursor: SystemMouseCursors.help,
              onEnter: (_) => _showTooltip(),
              child: GestureDetector(
                onTap: _showTooltip,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.help_outline_rounded,
                    size: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
