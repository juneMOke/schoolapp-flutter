import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';

/// Un choix parmi quelques valeurs, en puces : mode de versement, opérateur,
/// motif, nombre d'échéances. Les puces de choix du module RH.
class PayrollChoiceChips<T> extends StatelessWidget {
  final List<T> values;
  final T? selected;
  final String Function(T value) label;
  final ValueChanged<T>? onSelected;
  final IconData? Function(T value)? icon;

  const PayrollChoiceChips({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.icon,
  });

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final value in values)
        EteeloFilterChip(
          label: label(value),
          icon: icon?.call(value),
          selected: value == selected,
          color: AppColors.payrollValidated,
          soft: AppColors.payrollValidatedSoft,
          ink: AppColors.payrollValidatedInk,
          onTap: onSelected == null ? null : () => onSelected!(value),
        ),
    ],
  );
}
