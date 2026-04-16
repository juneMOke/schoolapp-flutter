import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/validation_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ValidatedYearSelector extends StatelessWidget {
  final AppLocalizations l10n;
  final double width;
  final bool validatedPreviousYear;
  final ValueChanged<bool> onChanged;
  final bool isChanged;
  final bool enabled;

  const ValidatedYearSelector({
    super.key,
    required this.l10n,
    required this.width,
    required this.validatedPreviousYear,
    required this.onChanged,
    this.isChanged = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final highlightColor = const Color(0xFF16A34A);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.yearValidated,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isChanged ? highlightColor : null,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: Text(l10n.yearValidated),
                selected: validatedPreviousYear,
                selectedColor: isChanged
                    ? highlightColor.withValues(alpha: 0.18)
                    : null,
                onSelected: enabled ? (_) => onChanged(true) : null,
              ),
              ChoiceChip(
                label: Text(l10n.yearNotValidated),
                selected: !validatedPreviousYear,
                selectedColor: isChanged
                    ? highlightColor.withValues(alpha: 0.18)
                    : null,
                onSelected: enabled ? (_) => onChanged(false) : null,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ValidationBadge(isValidated: validatedPreviousYear),
        ],
      ),
    );
  }
}
