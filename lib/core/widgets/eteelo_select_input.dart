import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_constants.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_popover_field.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_semantics.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_sheet.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';

export 'package:school_app_flutter/core/widgets/eteelo_select/eteelo_select_types.dart';

class EteeloSelectInput<T> extends StatefulWidget {
  final String label;
  final List<EteeloSelectItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  /// Lecture seule : le champ est non interactif mais garde l'apparence d'un
  /// champ au repos (pleine couleur), contrairement à [enabled] = false qui
  /// grise le champ (repère « non disponible », ex. cascade en édition).
  final bool readOnly;
  final bool required;
  final String? errorText;
  final String? placeholder;
  final String? Function(T?)? validator;
  final EteeloSelectPanelMode panelMode;
  final double minWidth;
  final double? menuMaxHeight;
  final Widget Function(
    BuildContext context,
    EteeloSelectItem<T> item,
    bool isSelected,
  )?
  itemBuilder;
  final Widget Function(BuildContext context, EteeloSelectItem<T> item)?
  selectedItemBuilder;

  const EteeloSelectInput({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.errorText,
    this.placeholder,
    this.validator,
    this.panelMode = EteeloSelectPanelMode.popover,
    this.minWidth = 180,
    this.menuMaxHeight,
    this.itemBuilder,
    this.selectedItemBuilder,
  });

  @override
  State<EteeloSelectInput<T>> createState() => _EteeloSelectInputState<T>();
}

class _EteeloSelectInputState<T> extends State<EteeloSelectInput<T>> {
  final _formFieldKey = GlobalKey<FormFieldState<T>>();

  late final FocusNode _focusNode;
  bool _isPanelOpen = false;

  // Interactif uniquement si activé ET pas en lecture seule.
  bool get _interactive => widget.enabled && !widget.readOnly;

  // Grisé (repère « non disponible ») uniquement si désactivé ET pas en
  // lecture seule : la lecture seule garde l'apparence pleine couleur.
  bool get _dimmed => !widget.enabled && !widget.readOnly;

  bool get _hasEditingFocus =>
      _interactive && (_focusNode.hasFocus || _isPanelOpen);

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant EteeloSelectInput<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.panelMode != oldWidget.panelMode && _isPanelOpen) {
      setState(() => _isPanelOpen = false);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  String? _selectedLabel(T? value) {
    if (value == null) return null;
    for (final item in widget.items) {
      if (item.value == value) return item.label;
    }
    return null;
  }

  Color _backgroundColor() =>
      _dimmed ? AppColors.surfaceAlt : AppColors.surface;

  Color _borderColor(String? resolvedErrorText) {
    if (_dimmed) return AppColors.stateDisabled;
    if (resolvedErrorText?.isNotEmpty ?? false) return AppColors.error;
    if (_hasEditingFocus) return AppColors.bleuArdoise;
    return AppColors.border;
  }

  double _borderWidth() => _hasEditingFocus
      ? EteeloSelectConstants.focusBorderWidth
      : EteeloSelectConstants.restBorderWidth;

  double _horizontalPadding() => _hasEditingFocus
      ? EteeloSelectConstants.focusHorizontalPadding
      : EteeloSelectConstants.restHorizontalPadding;

  BoxShadow? _focusRing() {
    if (!_hasEditingFocus) return null;
    return const BoxShadow(
      color: AppColors.stateFocus,
      blurRadius: 0,
      spreadRadius: 2,
    );
  }

  Future<void> _openSheet(FormFieldState<T> state) async {
    if (!_interactive) return;

    setState(() => _isPanelOpen = true);

    final result = await showEteeloSelectSheet<T>(
      context: context,
      items: widget.items,
      selectedValue: state.value,
      itemBuilder: widget.itemBuilder,
    );

    if (!mounted) return;
    setState(() => _isPanelOpen = false);

    if (result != null && result != state.value) {
      state.didChange(result);
      widget.onChanged(result);
    }
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: widget.minWidth),
      child: FormField<T>(
        key: _formFieldKey,
        initialValue: widget.value,
        validator: widget.validator,
        builder: (state) {
          final currentValue = widget.value;
          if (state.value != currentValue) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) state.didChange(currentValue);
            });
          }

          final resolvedErrorText = widget.errorText ?? state.errorText;
          final selectedLabel = _selectedLabel(state.value);
          final placeholder = resolveSelectPlaceholder(
            context,
            widget.placeholder,
          );
          final semanticLabel = resolveSelectSemanticLabel(
            context,
            widget.label,
            widget.required,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: _buildLabel()),
              const SizedBox(height: EteeloSelectConstants.labelGap),
              switch (widget.panelMode) {
                EteeloSelectPanelMode.popover => _buildPopoverField(
                  state: state,
                  selectedLabel: selectedLabel,
                  placeholder: placeholder,
                  resolvedErrorText: resolvedErrorText,
                  semanticLabel: semanticLabel,
                ),
                EteeloSelectPanelMode.sheet => _buildSheetField(
                  state: state,
                  selectedLabel: selectedLabel,
                  placeholder: placeholder,
                  resolvedErrorText: resolvedErrorText,
                  semanticLabel: semanticLabel,
                ),
              },
              if (resolvedErrorText != null &&
                  resolvedErrorText.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                ExcludeSemantics(
                  child: Text(
                    resolvedErrorText,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.error,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildLabel() {
    return Text.rich(
      TextSpan(
        text: widget.label,
        children: [
          if (widget.required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
        ],
      ),
      style: AppTypography.labelFormLarge.copyWith(
        color: AppColors.textPrimary,
        height: 1.3,
      ),
    );
  }

  Widget _buildPopoverField({
    required FormFieldState<T> state,
    required String? selectedLabel,
    required String placeholder,
    required String? resolvedErrorText,
    required String semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      value: selectedLabel ?? placeholder,
      textField: false,
      enabled: _interactive,
      readOnly: widget.readOnly,
      focused: _focusNode.hasFocus,
      child: Focus(
        focusNode: _focusNode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(
            minHeight: EteeloSelectConstants.fieldHeight,
          ),
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding()),
          decoration: BoxDecoration(
            color: _backgroundColor(),
            borderRadius: AppRadius.brSm,
            border: Border.all(
              color: _borderColor(resolvedErrorText),
              width: _borderWidth(),
            ),
            boxShadow: [if (_focusRing() != null) _focusRing()!],
          ),
          // Lecture seule : affichage statique (label + chevron) plutôt que le
          // DropdownButton, pour garder la pleine couleur sans son grisé Material.
          child: widget.readOnly
              ? _buildReadOnlyValue(selectedLabel, placeholder)
              : EteeloSelectPopoverField<T>(
                  value: state.value,
                  enabled: widget.enabled,
                  placeholder: placeholder,
                  menuMaxHeight: widget.menuMaxHeight,
                  items: widget.items,
                  itemBuilder: widget.itemBuilder,
                  selectedItemBuilder: widget.selectedItemBuilder,
                  onTap: () {
                    if (!widget.enabled) return;
                    setState(() => _isPanelOpen = true);
                  },
                  onChanged: !widget.enabled
                      ? null
                      : (value) {
                          setState(() => _isPanelOpen = false);
                          state.didChange(value);
                          widget.onChanged(value);
                        },
                ),
        ),
      ),
    );
  }

  Widget _buildReadOnlyValue(String? selectedLabel, String placeholder) {
    return Row(
      children: [
        Expanded(
          child: Text(
            selectedLabel ?? placeholder,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.bodyMedium.copyWith(
              color: selectedLabel == null
                  ? AppColors.textMuted
                  : AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Icon(
          Icons.keyboard_arrow_down_rounded,
          size: 18,
          color: AppColors.textMuted,
        ),
      ],
    );
  }

  Widget _buildSheetField({
    required FormFieldState<T> state,
    required String? selectedLabel,
    required String placeholder,
    required String? resolvedErrorText,
    required String semanticLabel,
  }) {
    return Semantics(
      label: semanticLabel,
      value: selectedLabel ?? placeholder,
      button: true,
      enabled: _interactive,
      readOnly: widget.readOnly,
      focused: _focusNode.hasFocus,
      child: Focus(
        focusNode: _focusNode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: EteeloSelectConstants.fieldHeight,
          padding: EdgeInsets.symmetric(horizontal: _horizontalPadding()),
          decoration: BoxDecoration(
            color: _backgroundColor(),
            borderRadius: AppRadius.brSm,
            border: Border.all(
              color: _borderColor(resolvedErrorText),
              width: _borderWidth(),
            ),
            boxShadow: [if (_focusRing() != null) _focusRing()!],
          ),
          child: InkWell(
            onTap: _interactive ? () => _openSheet(state) : null,
            borderRadius: AppRadius.brSm,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    selectedLabel ?? placeholder,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium.copyWith(
                      color: selectedLabel == null
                          ? AppColors.textMuted
                          : _dimmed
                          ? AppColors.stateDisabled
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
