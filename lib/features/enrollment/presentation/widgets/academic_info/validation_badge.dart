import 'package:flutter/material.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ValidationBadge extends StatelessWidget {
  final bool isValidated;

  const ValidationBadge({super.key, required this.isValidated});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = isValidated ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValidated ? Icons.check_circle : Icons.cancel,
            color: isValidated ? Colors.green[600] : Colors.red[600],
            size: 18,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              isValidated ? l10n.yearValidated : l10n.yearNotValidated,
              style: TextStyle(
                color: isValidated ? Colors.green[600] : Colors.red[600],
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
