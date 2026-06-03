import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

enum EteeloSelectPanelMode { popover, sheet }

class EteeloSelectItem<T> {
  final T value;
  final String label;
  final bool enabled;

  const EteeloSelectItem({
    required this.value,
    required this.label,
    this.enabled = true,
  });
}

class EteeloSelectInput<T> extends StatefulWidget {
  final String label;
  final List<EteeloSelectItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final bool enabled;
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
  static const double _fieldHeight = AppDimensions.minTouchTarget - 2;
  static const double _restBorderWidth = 1;
  static const double _focusBorderWidth = 2;
  static const double _restHorizontalPadding = AppSpacing.md;
  static const double _focusHorizontalPadding = AppSpacing.md - 1;
  static const double _labelGap = AppSpacing.sm - 2;

  final _formFieldKey = GlobalKey<FormFieldState<T>>();

  late FocusNode _focusNode;
  late bool _ownsFocusNode;
  bool _isPanelOpen = false;

  bool get _hasEditingFocus => _focusNode.hasFocus || _isPanelOpen;

  @override
  void initState() {
    super.initState();
    _setupFocusNode();
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
    _teardownFocusNode();
    super.dispose();
  }

  void _setupFocusNode() {
    _focusNode = FocusNode();
    _ownsFocusNode = true;
    _focusNode.addListener(_handleFocusChanged);
  }

  void _teardownFocusNode() {
    _focusNode.removeListener(_handleFocusChanged);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    setState(() {});
  }

  String _resolvedPlaceholder(BuildContext context) {
    final fromWidget = widget.placeholder?.trim() ?? '';
    if (fromWidget.isNotEmpty) {
      return fromWidget;
    }
    return AppLocalizations.of(context)?.selectPlaceholderChoose ?? 'Choisir';
  }

  String? _selectedLabel(T? value) {
    if (value == null) return null;
    for (final item in widget.items) {
      if (item.value == value) return item.label;
    }
    return null;
  }

  Color _backgroundColor() =>
      widget.enabled ? AppColors.surface : AppColors.surfaceAlt;

  Color _borderColor(String? resolvedErrorText) {
    if (!widget.enabled) return AppColors.stateDisabled;
    if (resolvedErrorText?.isNotEmpty ?? false) return AppColors.error;
    if (_hasEditingFocus) return AppColors.bleuArdoise;
    return AppColors.border;
  }

  double _borderWidth() =>
      _hasEditingFocus ? _focusBorderWidth : _restBorderWidth;

  double _horizontalPadding() =>
      _hasEditingFocus ? _focusHorizontalPadding : _restHorizontalPadding;

  BoxShadow? _focusRing() {
    if (!_hasEditingFocus) return null;
    return const BoxShadow(
      color: AppColors.stateFocus,
      blurRadius: 0,
      spreadRadius: 2,
    );
  }

  Future<void> _openSheet(FormFieldState<T> state) async {
    if (!widget.enabled) return;

    setState(() => _isPanelOpen = true);

    final result = await showModalBottomSheet<T>(
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
          itemCount: widget.items.length,
          separatorBuilder: (_, _) =>
              const Divider(height: AppSpacing.sm, color: AppColors.border),
          itemBuilder: (context, index) {
            final item = widget.items[index];
            final isSelected = item.value == state.value;
            final content = widget.itemBuilder?.call(context, item, isSelected);
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
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
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
          final placeholder = _resolvedPlaceholder(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: _buildLabel()),
              const SizedBox(height: _labelGap),
              switch (widget.panelMode) {
                EteeloSelectPanelMode.popover => _buildPopoverField(
                  state: state,
                  selectedLabel: selectedLabel,
                  placeholder: placeholder,
                  resolvedErrorText: resolvedErrorText,
                ),
                EteeloSelectPanelMode.sheet => _buildSheetField(
                  state: state,
                  selectedLabel: selectedLabel,
                  placeholder: placeholder,
                  resolvedErrorText: resolvedErrorText,
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
  }) {
    return Semantics(
      label: widget.required ? '${widget.label}, obligatoire' : widget.label,
      value: selectedLabel ?? placeholder,
      textField: false,
      enabled: widget.enabled,
      focused: _focusNode.hasFocus,
      child: Focus(
        focusNode: _focusNode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          constraints: const BoxConstraints(minHeight: _fieldHeight),
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
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: state.value,
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
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              menuMaxHeight: widget.menuMaxHeight,
              borderRadius: AppRadius.brSm,
              style: AppTypography.bodyMedium.copyWith(
                color: widget.enabled
                    ? AppColors.textPrimary
                    : AppColors.stateDisabled,
              ),
              selectedItemBuilder: widget.selectedItemBuilder == null
                  ? null
                  : (context) => widget.items
                        .map(
                          (item) => widget.selectedItemBuilder!(context, item),
                        )
                        .toList(growable: false),
              items: widget.items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item.value,
                      enabled: item.enabled,
                      child:
                          widget.itemBuilder?.call(
                            context,
                            item,
                            item.value == state.value,
                          ) ??
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    ),
                  )
                  .toList(growable: false),
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
      ),
    );
  }

  Widget _buildSheetField({
    required FormFieldState<T> state,
    required String? selectedLabel,
    required String placeholder,
    required String? resolvedErrorText,
  }) {
    return Semantics(
      label: widget.required ? '${widget.label}, obligatoire' : widget.label,
      value: selectedLabel ?? placeholder,
      button: true,
      enabled: widget.enabled,
      focused: _focusNode.hasFocus,
      child: Focus(
        focusNode: _focusNode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: _fieldHeight,
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
            onTap: widget.enabled ? () => _openSheet(state) : null,
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
                          : widget.enabled
                          ? AppColors.textPrimary
                          : AppColors.stateDisabled,
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
