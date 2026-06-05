import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';

class EteeloSelectPopoverField<T> extends StatelessWidget {
  final T? value;
  final bool enabled;
  final String placeholder;
  final double? menuMaxHeight;
  final List<EteeloSelectItem<T>> items;
  final void Function()? onTap;
  final ValueChanged<T?>? onChanged;
  final Widget Function(
    BuildContext context,
    EteeloSelectItem<T> item,
    bool isSelected,
  )?
  itemBuilder;
  final Widget Function(BuildContext context, EteeloSelectItem<T> item)?
  selectedItemBuilder;

  const EteeloSelectPopoverField({
    super.key,
    required this.value,
    required this.enabled,
    required this.placeholder,
    required this.menuMaxHeight,
    required this.items,
    required this.onTap,
    required this.onChanged,
    required this.itemBuilder,
    required this.selectedItemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    // DropdownButton (Material) impose : la valeur doit correspondre à
    // EXACTEMENT un item, et deux items ne peuvent pas partager la même valeur.
    // Pendant le chargement/cascade de la geo-adresse, la valeur sélectionnée
    // peut ne pas (encore) figurer dans les options, et certaines listes
    // peuvent contenir des doublons → on dédoublonne par valeur et on
    // n'attribue la valeur que si elle correspond à un item (sinon on retombe
    // sur le hint au lieu de planter).
    final seen = <T>{};
    final uniqueItems = <EteeloSelectItem<T>>[
      for (final item in items)
        if (seen.add(item.value)) item,
    ];
    final hasValue =
        value != null && uniqueItems.any((item) => item.value == value);
    final effectiveValue = hasValue ? value : null;

    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: effectiveValue,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: AppColors.textMuted,
        ),
        hint: Text(
          placeholder,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
        ),
        menuMaxHeight: menuMaxHeight,
        borderRadius: AppRadius.brSm,
        style: AppTypography.bodyMedium.copyWith(
          color: enabled ? AppColors.textPrimary : AppColors.stateDisabled,
        ),
        selectedItemBuilder: selectedItemBuilder == null
            ? null
            : (context) => uniqueItems
                  .map((item) => selectedItemBuilder!(context, item))
                  .toList(growable: false),
        items: uniqueItems
            .map(
              (item) => DropdownMenuItem<T>(
                value: item.value,
                enabled: item.enabled,
                child:
                    itemBuilder?.call(context, item, item.value == value) ??
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
              ),
            )
            .toList(growable: false),
        onTap: onTap,
        onChanged: onChanged,
      ),
    );
  }
}
