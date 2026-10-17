import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';

/// Builder de trailing, extensible sans modifier le composant principal.
typedef DataTableTrailingBuilder =
    Widget Function(BuildContext context, DataTableTrailingSpec spec);

/// Registry centrale des trailing widgets.
class DataTableTrailingRegistry {
  const DataTableTrailingRegistry._();

  static final Map<DataTableTrailingType, DataTableTrailingBuilder>
  _defaultBuilders = {
    DataTableTrailingType.none: (_, _) => const SizedBox.shrink(),
    DataTableTrailingType.eye: (context, spec) =>
        _DefaultTrailingIconButton(spec: spec, icon: Icons.visibility_outlined),
    DataTableTrailingType.chevronOpen: (context, spec) =>
        _DefaultTrailingIconButton(
          spec: spec,
          icon: Icons.keyboard_arrow_down_rounded,
        ),
    DataTableTrailingType.chevronClose: (context, spec) =>
        _DefaultTrailingIconButton(
          spec: spec,
          icon: Icons.keyboard_arrow_right_rounded,
        ),
  };

  static Widget build(
    BuildContext context,
    DataTableTrailingSpec spec, {
    Map<DataTableTrailingType, DataTableTrailingBuilder> customBuilders =
        const {},
  }) {
    final builder =
        customBuilders[spec.type] ??
        _defaultBuilders[spec.type] ??
        _defaultBuilders[DataTableTrailingType.none]!;

    return builder(context, spec);
  }
}

class _DefaultTrailingIconButton extends StatelessWidget {
  final DataTableTrailingSpec spec;
  final IconData icon;

  const _DefaultTrailingIconButton({required this.spec, required this.icon});

  @override
  Widget build(BuildContext context) {
    final isEnabled = spec.enabled && spec.onTap != null;
    final tooltip = spec.tooltip;
    final semanticLabel = spec.semanticLabel ?? tooltip;
    const slotSize =
        EteeloDataTableTheme.trailingSlotWidth -
        (EteeloDataTableTheme.focusRingOffset * 2);

    final button = Semantics(
      button: true,
      enabled: isEnabled,
      label: semanticLabel,
      child: EteeloActivatable(
        onActivate: isEnabled ? spec.onTap : null,
        builder: (context, highlight) => AnimatedContainer(
          duration: AppMotion.fast,
          padding: const EdgeInsets.all(EteeloDataTableTheme.focusRingOffset),
          width: slotSize,
          height: slotSize,
          decoration: BoxDecoration(
            color: isEnabled
                ? (highlight.hovered
                      ? EteeloDataTableTheme.headerSortActiveColor
                      : EteeloDataTableTheme.headerSortActiveColor.withValues(
                          alpha: 0.08,
                        ))
                : AppColors.stateDisabled.withValues(alpha: 0.12),
            borderRadius: AppRadius.brSm,
            border: highlight.focused
                ? Border.all(
                    color: EteeloDataTableTheme.focusRingColor,
                    width: EteeloDataTableTheme.focusRingWidth,
                  )
                : null,
          ),
          child: Icon(
            icon,
            size: 16,
            color: isEnabled
                ? (highlight.hovered
                      ? AppColors.textOnDark
                      : EteeloDataTableTheme.headerSortActiveColor)
                : AppColors.stateDisabled,
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
