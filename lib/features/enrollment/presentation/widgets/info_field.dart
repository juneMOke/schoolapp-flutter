import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoField extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final int maxLines;
  final bool isNumeric;
  final bool isPhone;
  final bool isEmail;

  const InfoField({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.maxLines = 1,
    this.isNumeric = false,
    this.isPhone = false,
    this.isEmail = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon!, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: _handleTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: AppRadius.brSm,
              color: _getBackgroundColor(),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: _getTextColor(),
                decoration: _getDecoration(),
              ),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  Color _getBackgroundColor() {
    if (isPhone || isEmail) {
      return AppColors.info.withValues(alpha: 0.12);
    }
    if (isNumeric && value != 'N/A') {
      return AppColors.success.withValues(alpha: 0.12);
    }
    return AppColors.surfaceAlt;
  }

  Color _getTextColor() {
    if (isPhone || isEmail) {
      return AppColors.info;
    }
    if (isNumeric && value != 'N/A') {
      return AppColors.success;
    }
    return AppColors.textPrimary;
  }

  TextDecoration? _getDecoration() {
    return (isPhone || isEmail) ? TextDecoration.underline : null;
  }

  void _handleTap() {
    if (isPhone) {
      launchUrl(Uri.parse('tel:$value'));
    } else if (isEmail) {
      launchUrl(Uri.parse('mailto:$value'));
    }
  }
}
