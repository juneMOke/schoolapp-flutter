import 'package:flutter/material.dart';
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

class _DefaultTrailingIconButton extends StatefulWidget {
  final DataTableTrailingSpec spec;
  final IconData icon;

  const _DefaultTrailingIconButton({required this.spec, required this.icon});

  @override
  State<_DefaultTrailingIconButton> createState() =>
      _DefaultTrailingIconButtonState();
}

class _DefaultTrailingIconButtonState
    extends State<_DefaultTrailingIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isEnabled = widget.spec.enabled && widget.spec.onTap != null;
    final tooltip = widget.spec.tooltip;

    final button = MouseRegion(
      onEnter: (_) => isEnabled ? setState(() => _isHovered = true) : null,
      onExit: (_) => isEnabled ? setState(() => _isHovered = false) : null,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isEnabled
              ? (_isHovered
                    ? EteeloDataTableTheme.headerSortActiveColor
                    : EteeloDataTableTheme.headerSortActiveColor.withValues(
                        alpha: 0.08,
                      ))
              : AppColors.stateDisabled.withValues(alpha: 0.12),
          borderRadius: AppRadius.brSm,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: AppRadius.brSm,
            onTap: isEnabled ? widget.spec.onTap : null,
            child: Icon(
              widget.icon,
              size: 16,
              color: isEnabled
                  ? (_isHovered
                        ? AppColors.textOnDark
                        : EteeloDataTableTheme.headerSortActiveColor)
                  : AppColors.stateDisabled,
            ),
          ),
        ),
      ),
    );

    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}
