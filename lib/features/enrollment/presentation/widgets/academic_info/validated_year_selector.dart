import 'package:flutter/material.dart';
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
    final successColor = const Color(0xFF16A34A);
    final errorColor = const Color(0xFFDC2626);

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.yearValidated,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isChanged ? successColor : null,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ValidationChip(
                label: l10n.yearValidated,
                isSelected: validatedPreviousYear,
                activeColor: successColor,
                icon: Icons.check_circle_rounded,
                onSelected: enabled ? () => onChanged(true) : null,
              ),
              _ValidationChip(
                label: l10n.yearNotValidated,
                isSelected: !validatedPreviousYear,
                activeColor: errorColor,
                icon: Icons.cancel_rounded,
                onSelected: enabled ? () => onChanged(false) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ValidationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final IconData icon;
  final VoidCallback? onSelected;

  const _ValidationChip({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.icon,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      avatar: isSelected
          ? Icon(
              icon,
              size: 18,
              color: activeColor,
            )
          : null,
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected != null ? (_) => onSelected!() : null,
      selectedColor: activeColor.withValues(alpha: 0.12),
      checkmarkColor: activeColor,
      labelStyle: TextStyle(
        color: isSelected ? activeColor : null,
        fontWeight: isSelected ? FontWeight.bold : null,
      ),
      side: BorderSide(
        color: isSelected ? activeColor : Colors.grey.shade300,
        width: isSelected ? 1.5 : 1.0,
      ),
      showCheckmark: false,
    );
  }
}
