import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';

Future<T?> showEteeloSelectSheet<T>({
  required BuildContext context,
  required List<EteeloSelectItem<T>> items,
  required T? selectedValue,
  required Widget Function(
    BuildContext context,
    EteeloSelectItem<T> item,
    bool isSelected,
  )?
  itemBuilder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.surface,
    constraints: const BoxConstraints(maxWidth: 640),
    builder: (context) => SafeArea(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        itemCount: items.length,
        separatorBuilder: (_, _) =>
            const Divider(height: AppSpacing.sm, color: AppColors.border),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item.value == selectedValue;
          final content = itemBuilder?.call(context, item, isSelected);
          return ListTile(
            enabled: item.enabled,
            contentPadding: EdgeInsets.zero,
            minLeadingWidth: 0,
            title:
                content ??
                Text(
                  item.label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: item.enabled
                        ? AppColors.textPrimary
                        : AppColors.stateDisabled,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
            trailing: content == null && isSelected
                ? const Icon(
                    Icons.check_rounded,
                    color: AppColors.bleuArdoise,
                    size: 18,
                  )
                : null,
            onTap: item.enabled
                ? () => Navigator.of(context).pop<T>(item.value)
                : null,
          );
        },
      ),
    ),
  );
}
