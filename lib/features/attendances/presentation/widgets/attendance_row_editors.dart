import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/absence_reason.dart';
import 'package:school_app_flutter/features/attendances/presentation/helpers/attendance_page_helpers.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AttendancePresenceSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AttendancePresenceSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedBackground = value ? AppColors.success : AppColors.danger;

    return Semantics(
      label: l10n.attendancePresenceStatusLabel,
      value: value ? l10n.attendancePresentValue : l10n.attendanceAbsentValue,
      child: SegmentedButton<bool>(
        segments: [
          ButtonSegment<bool>(
            value: true,
            label: Text(l10n.attendancePresentValue),
          ),
          ButtonSegment<bool>(
            value: false,
            label: Text(l10n.attendanceAbsentValue),
          ),
        ],
        selected: {value},
        onSelectionChanged: (selection) {
          final target = selection.firstOrNull;
          if (target == null || target == value) {
            return;
          }
          onChanged(target);
        },
        style: SegmentedButton.styleFrom(
          backgroundColor: Colors.transparent,
          selectedBackgroundColor: selectedBackground,
          selectedForegroundColor: Colors.white,
          foregroundColor: AppColors.textSecondary,
          side: const BorderSide(color: AppColors.border),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: AppTextStyles.caption.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class AttendanceAbsenceReasonField extends StatelessWidget {
  final AbsenceReason? value;
  final bool enabled;
  final bool showValidationError;
  final bool autofocus;
  final ValueChanged<AbsenceReason?> onChanged;

  const AttendanceAbsenceReasonField({
    super.key,
    required this.value,
    required this.enabled,
    required this.showValidationError,
    this.autofocus = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasMissingReason = enabled && showValidationError;
    final accent = hasMissingReason
        ? AppColors.terreCuite.withValues(alpha: 0.65)
        : AppColors.border;

    return DropdownButtonFormField<AbsenceReason>(
      initialValue: value,
      autofocus: autofocus,
      isExpanded: true,
      icon: const Icon(Icons.keyboard_arrow_down_rounded),
      iconEnabledColor: AppColors.textSecondary,
      iconDisabledColor: AppColors.textMuted,
      dropdownColor: AppColors.surface,
      borderRadius: BorderRadius.circular(AppDimensions.spacingS),
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: l10n.attendanceTableAbsenceReason,
        helperText: enabled
            ? (hasMissingReason ? l10n.attendanceReasonRequiredHint : null)
            : l10n.attendanceReasonDisabledHint,
        filled: true,
        fillColor: enabled
            ? AppColors.background
            : AppColors.financeDetailMutedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          borderSide: BorderSide(color: accent),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          borderSide: BorderSide(color: accent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          borderSide: BorderSide(
            color: hasMissingReason
                ? AppColors.terreCuite
                : AppColors.classesFocusRing,
            width: 1.6,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingS,
          vertical: AppDimensions.spacingS,
        ),
      ),
      items: AbsenceReason.values
          .map(
            (reason) => DropdownMenuItem<AbsenceReason>(
              value: reason,
              child: Text(
                AttendancePageHelpers.absenceReasonLabel(l10n, reason),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(growable: false),
      onChanged: enabled ? onChanged : null,
    );
  }
}

class AttendanceAbsenceNoteField extends StatefulWidget {
  final String value;
  final bool enabled;
  final ValueChanged<String> onChanged;

  const AttendanceAbsenceNoteField({
    super.key,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<AttendanceAbsenceNoteField> createState() =>
      _AttendanceAbsenceNoteFieldState();
}

class _AttendanceAbsenceNoteFieldState
    extends State<AttendanceAbsenceNoteField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant AttendanceAbsenceNoteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value &&
        oldWidget.enabled == widget.enabled) {
      return;
    }

    if (_controller.text == widget.value) {
      return;
    }

    _controller.value = TextEditingValue(
      text: widget.value,
      selection: TextSelection.collapsed(offset: widget.value.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return TextField(
      controller: _controller,
      enabled: widget.enabled,
      minLines: 1,
      maxLines: 2,
      onChanged: widget.onChanged,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: l10n.attendanceTableAbsenceReasonNote,
        hintText: l10n.attendanceNotePlaceholder,
        helperText: widget.enabled ? null : l10n.attendanceNoteDisabledHint,
        filled: true,
        fillColor: widget.enabled
            ? AppColors.background
            : AppColors.financeDetailMutedSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          borderSide: const BorderSide(
            color: AppColors.classesFocusRing,
            width: 1.6,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingS,
          vertical: AppDimensions.spacingS,
        ),
      ),
    );
  }
}
