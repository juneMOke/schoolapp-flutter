import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';

/// Champ de saisie de date avec calendrier intégré.
///
/// Expose [value] (DateTime?) et [onChanged] plutôt qu'un [TextEditingController].
/// S'intègre dans un [Form] via [FormField<DateTime>] et supporte [validator].
///
/// Usage minimal :
/// ```dart
/// EteeloDateInput(
///   label: l10n.dateOfBirth,
///   placeholder: l10n.dateHint,
///   value: _selectedDate,
///   onChanged: (date) => setState(() => _selectedDate = date),
/// )
/// ```
class EteeloDateInput extends StatefulWidget {
  final String label;
  final String? placeholder;
  final DateTime? value;
  final ValueChanged<DateTime?>? onChanged;
  final bool required;
  final bool enabled;
  final String? errorText;
  final String? Function(DateTime?)? validator;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final DateTime? initialPickerDate;

  /// Paramètres optionnels passés au [showDatePicker] natif.
  final Locale? locale;
  final String? helpText;
  final String? cancelText;
  final String? confirmText;

  const EteeloDateInput({
    super.key,
    required this.label,
    this.placeholder,
    this.value,
    this.onChanged,
    this.required = false,
    this.enabled = true,
    this.errorText,
    this.validator,
    this.firstDate,
    this.lastDate,
    this.initialPickerDate,
    this.locale,
    this.helpText,
    this.cancelText,
    this.confirmText,
  });

  @override
  State<EteeloDateInput> createState() => _EteeloDateInputState();
}

class _EteeloDateInputState extends State<EteeloDateInput> {
  static const double _fieldHeight = AppDimensions.minTouchTarget - 2;
  static const double _restBorderWidth = 1;
  static const double _focusBorderWidth = 2;
  static const double _restHorizontalPadding = AppSpacing.md;
  static const double _focusHorizontalPadding = AppSpacing.md - 1;
  static const double _labelGap = AppSpacing.sm - 2;

  final _formFieldKey = GlobalKey<FormFieldState<DateTime>>();

  /// Vrai pendant l'ouverture du calendrier — simule le focus visuel.
  bool _isPickerOpen = false;

  // ── Formatage ──────────────────────────────────────────────────────────────

  String _formatDate(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m/${date.year}';
  }

  // ── Styles dynamiques ──────────────────────────────────────────────────────

  Color _borderColor(String? resolvedErrorText) {
    if (!widget.enabled) return AppColors.stateDisabled;
    if (resolvedErrorText != null && resolvedErrorText.isNotEmpty) {
      return AppColors.error;
    }
    if (_isPickerOpen) return AppColors.bleuArdoise;
    return AppColors.border;
  }

  double _borderWidth() => _isPickerOpen ? _focusBorderWidth : _restBorderWidth;

  double _horizontalPadding() =>
      _isPickerOpen ? _focusHorizontalPadding : _restHorizontalPadding;

  BoxShadow? _focusRing() {
    if (!_isPickerOpen) return null;
    return const BoxShadow(
      color: AppColors.stateFocus,
      blurRadius: 0,
      spreadRadius: 2,
    );
  }

  Color _backgroundColor() =>
      widget.enabled ? AppColors.surface : AppColors.surfaceAlt;

  // ── Interaction ────────────────────────────────────────────────────────────

  Future<void> _pickDate(FormFieldState<DateTime> state) async {
    if (!widget.enabled) return;

    setState(() => _isPickerOpen = true);

    final picked = await showDatePicker(
      context: context,
      initialDate: widget.value ?? widget.initialPickerDate ?? DateTime.now(),
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? DateTime.now(),
      locale: widget.locale,
      helpText: widget.helpText,
      cancelText: widget.cancelText,
      confirmText: widget.confirmText,
    );

    if (!mounted) return;
    setState(() => _isPickerOpen = false);

    if (picked != null) {
      state.didChange(picked);
      widget.onChanged?.call(picked);
    }
  }

  // ── Sémantique ─────────────────────────────────────────────────────────────

  String get _semanticLabel =>
      widget.required ? '${widget.label}, obligatoire' : widget.label;

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FormField<DateTime>(
      key: _formFieldKey,
      initialValue: widget.value,
      validator: widget.validator,
      builder: (state) {
        // Synchronise l'état interne lorsque `value` change depuis le parent.
        final currentValue = widget.value;
        if (state.value != currentValue) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) state.didChange(currentValue);
          });
        }

        final resolvedErrorText = widget.errorText ?? state.errorText;
        final displayText = state.value != null
            ? _formatDate(state.value!)
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: _buildLabel()),
            const SizedBox(height: _labelGap),
            _buildField(state, resolvedErrorText, displayText),
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

  Widget _buildField(
    FormFieldState<DateTime> state,
    String? resolvedErrorText,
    String? displayText,
  ) {
    return Semantics(
      label: _semanticLabel,
      value: displayText,
      button: true,
      enabled: widget.enabled,
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
        child: GestureDetector(
          onTap: widget.enabled ? () => _pickDate(state) : null,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  displayText ?? (widget.placeholder ?? ''),
                  style: AppTypography.bodyMedium.copyWith(
                    color: displayText != null
                        ? (widget.enabled
                              ? AppColors.textPrimary
                              : AppColors.textMuted)
                        : AppColors.textMuted,
                    height: 1.3,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_today_rounded,
                size: 16,
                color: widget.enabled
                    ? AppColors.bleuArdoise
                    : AppColors.stateDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
