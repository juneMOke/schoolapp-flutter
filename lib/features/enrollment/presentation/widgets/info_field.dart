import 'package:flutter/material.dart';
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
              Icon(icon!, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
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
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
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
      return Colors.blue[50]!;
    }
    if (isNumeric && value != 'N/A') {
      return Colors.green[50]!;
    }
    return Colors.grey[50]!;
  }

  Color _getTextColor() {
    if (isPhone || isEmail) {
      return Colors.blue[700]!;
    }
    if (isNumeric && value != 'N/A') {
      return Colors.green[700]!;
    }
    return Colors.black87;
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
