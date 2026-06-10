import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

enum EteeloTextInputType { text, phone, email, number, multiline }

class EteeloTextInput extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? placeholder;
  final EteeloTextInputType keyboardType;
  final bool readOnly;
  final bool required;
  final bool enabled;
  final String? errorText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final int? minLines;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;

  const EteeloTextInput({
    super.key,
    required this.controller,
    required this.label,
    this.placeholder,
    this.keyboardType = EteeloTextInputType.text,
    this.readOnly = false,
    this.required = false,
    this.enabled = true,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.focusNode,
    this.textInputAction,
    this.autofillHints,
    this.minLines,
    this.maxLines = 1,
    this.inputFormatters,
  });

  @override
  State<EteeloTextInput> createState() => _EteeloTextInputState();
}

class _EteeloTextInputState extends State<EteeloTextInput> {
  static const double _fieldHeight = AppDimensions.minTouchTarget - 2;
  static const double _restBorderWidth = 1;
  static const double _focusBorderWidth = 2;
  static const double _restHorizontalPadding = AppSpacing.md;
  static const double _focusHorizontalPadding = AppSpacing.md - 1;
  static const double _labelGap = AppSpacing.sm - 2;

  final _formFieldKey = GlobalKey<FormFieldState<String>>();

  late FocusNode _focusNode;
  late bool _ownsFocusNode;

  bool get _isSingleLine => widget.maxLines == 1 && widget.minLines == null;

  bool get _hasEditingFocus =>
      _focusNode.hasFocus && widget.enabled && !widget.readOnly;

  @override
  void initState() {
    super.initState();
    _setupFocusNode();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(covariant EteeloTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
      _syncFormFieldValue();
    }

    if (oldWidget.focusNode != widget.focusNode) {
      _teardownFocusNode();
      _setupFocusNode();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    _teardownFocusNode();
    super.dispose();
  }

  void _setupFocusNode() {
    _focusNode = widget.focusNode ?? FocusNode();
    _ownsFocusNode = widget.focusNode == null;
    _focusNode.addListener(_handleFocusChanged);
  }

  void _teardownFocusNode() {
    _focusNode.removeListener(_handleFocusChanged);
    if (_ownsFocusNode) {
      _focusNode.dispose();
    }
  }

  void _handleFocusChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _handleControllerChanged() {
    _syncFormFieldValue();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  void _syncFormFieldValue() {
    final state = _formFieldKey.currentState;
    final value = widget.controller.text;
    if (state != null && state.value != value) {
      state.didChange(value);
    }
  }

  TextInputType get _textInputType => switch (widget.keyboardType) {
    EteeloTextInputType.phone => TextInputType.phone,
    EteeloTextInputType.email => TextInputType.emailAddress,
    EteeloTextInputType.number => const TextInputType.numberWithOptions(
      decimal: true,
    ),
    EteeloTextInputType.multiline => TextInputType.multiline,
    EteeloTextInputType.text => TextInputType.text,
  };

  String get _semanticLabel =>
      widget.required ? '${widget.label}, obligatoire' : widget.label;

  String? _semanticHint(String? resolvedErrorText) {
    final parts = <String>[];
    if (widget.placeholder?.isNotEmpty ?? false) {
      parts.add(widget.placeholder!);
    }
    if (resolvedErrorText?.isNotEmpty ?? false) {
      parts.add('Erreur: ${resolvedErrorText!}');
    }
    if (parts.isEmpty) {
      return null;
    }
    return parts.join('. ');
  }

  // Pas de couleur particulière en lecture (readOnly / désactivé) : un champ
  // non éditable conserve l'apparence d'un champ au repos (même fond, bordure
  // et couleur de texte que l'état éditable). Seul l'état focus se distingue.
  Color _backgroundColor() => AppColors.surface;

  Color _borderColor(String? resolvedErrorText) {
    if (resolvedErrorText != null && resolvedErrorText.isNotEmpty) {
      return AppColors.error;
    }
    if (_hasEditingFocus) {
      return AppColors.bleuArdoise;
    }
    return AppColors.border;
  }

  double _borderWidth() =>
      _hasEditingFocus ? _focusBorderWidth : _restBorderWidth;

  double _horizontalPadding() =>
      _hasEditingFocus ? _focusHorizontalPadding : _restHorizontalPadding;

  BoxShadow? _focusRing() {
    if (!_hasEditingFocus) {
      return null;
    }

    return const BoxShadow(
      color: AppColors.stateFocus,
      blurRadius: 0,
      spreadRadius: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: _formFieldKey,
      initialValue: widget.controller.text,
      validator: widget.validator,
      builder: (state) {
        final resolvedErrorText = widget.errorText ?? state.errorText;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: _buildLabel()),
            const SizedBox(height: _labelGap),
            _buildField(state, resolvedErrorText),
            if (resolvedErrorText != null && resolvedErrorText.isNotEmpty) ...[
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

  Widget _buildField(FormFieldState<String> state, String? resolvedErrorText) {
    final field = TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      keyboardType: _textInputType,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      onTap: widget.onTap,
      onSubmitted: widget.onSubmitted,
      onChanged: (value) {
        state.didChange(value);
        widget.onChanged?.call(value);
      },
      textInputAction: widget.textInputAction,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      textAlignVertical: TextAlignVertical.center,
      cursorColor: AppColors.bleuArdoise,
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      decoration: InputDecoration(
        isCollapsed: true,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        hintText: widget.placeholder,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textMuted,
          height: 1.3,
        ),
      ),
    );

    return Semantics(
      label: _semanticLabel,
      hint: _semanticHint(resolvedErrorText),
      value: widget.controller.text.isEmpty ? null : widget.controller.text,
      textField: true,
      enabled: widget.enabled,
      focused: _focusNode.hasFocus,
      readOnly: widget.readOnly,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        constraints: BoxConstraints(
          minHeight: _fieldHeight,
          maxHeight: _isSingleLine ? _fieldHeight : double.infinity,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: _horizontalPadding(),
          vertical: _isSingleLine ? 0 : AppSpacing.md - 1,
        ),
        decoration: BoxDecoration(
          color: _backgroundColor(),
          borderRadius: AppRadius.brSm,
          border: Border.all(
            color: _borderColor(resolvedErrorText),
            width: _borderWidth(),
          ),
          boxShadow: [if (_focusRing() != null) _focusRing()!],
        ),
        alignment: _isSingleLine ? Alignment.centerLeft : Alignment.topLeft,
        child: field,
      ),
    );
  }
}
