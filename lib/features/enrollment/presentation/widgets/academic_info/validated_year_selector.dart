import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/validation_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ValidatedYearSelector extends StatelessWidget {
  final AppLocalizations l10n;
  final double width;
  final bool validatedPreviousYear;
  final ValueChanged<bool> onChanged;

  const ValidatedYearSelector({
    super.key,
    required this.l10n,
    required this.width,
    required this.validatedPreviousYear,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.yearValidated,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
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
                onSelected: (_) => onChanged(true),
              ),
              ChoiceChip(
                label: Text(l10n.yearNotValidated),
                selected: !validatedPreviousYear,
                onSelected: (_) => onChanged(false),
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
