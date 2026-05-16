import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_card.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_compact_layout.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_status_dropdown.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_title.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_wide_layout.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SearchForm extends StatefulWidget {
  final String academicYearId;
  final String status;
  final bool isLoading;
  final EnrollmentSearchDispatcher dispatch;
  final bool showStatusFilter;
  final ValueChanged<String>? onStatusChanged;

  const SearchForm({
    super.key,
    required this.academicYearId,
    required this.status,
    required this.isLoading,
    required this.dispatch,
    this.showStatusFilter = false,
    this.onStatusChanged,
  });

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();

  DateTime? _lastActionAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SearchFormCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final isWide = constraints.maxWidth >= AppBreakpoints.formWideMin;
          final isMedium = constraints.maxWidth >= AppBreakpoints.formMediumMin;
          final columns = isMedium ? 3 : 1;
          final title = SearchFormTitle(label: l10n.searchStudents);
          final actions = _buildActionButtons(context, l10n);
          final statusDropdown = widget.showStatusFilter
              ? SearchFormStatusDropdown(
                  selectedStatus: widget.status,
                  onChanged: (value) => widget.onStatusChanged?.call(value),
                )
              : null;

          if (isWide) {
            return SearchFormWideLayout(
              title: title,
              spacing: spacing,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              surnameController: _surnameController,
              dateOfBirthController: _dateOfBirthController,
              firstNameLabel: l10n.firstName,
              lastNameLabel: l10n.lastName,
              surnameLabel: l10n.surname,
              dateOfBirthLabel: l10n.dateOfBirth,
              onFieldChanged: (_) => _onFieldChanged(),
              onDateTap: () => _selectDate(context),
              actions: actions,
              statusDropdown: statusDropdown,
            );
          }

          final calculatedWidth =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
          final fieldWidth = calculatedWidth.clamp(170.0, 360.0).toDouble();

          return SearchFormCompactLayout(
            title: title,
            spacing: spacing,
            fieldWidth: fieldWidth,
            availableWidth: constraints.maxWidth,
            firstNameController: _firstNameController,
            lastNameController: _lastNameController,
            surnameController: _surnameController,
            dateOfBirthController: _dateOfBirthController,
            firstNameLabel: l10n.firstName,
            lastNameLabel: l10n.lastName,
            surnameLabel: l10n.surname,
            dateOfBirthLabel: l10n.dateOfBirth,
            onFieldChanged: (_) => _onFieldChanged(),
            onDateTap: () => _selectDate(context),
            actions: actions,
            statusDropdown: statusDropdown,
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    final hasDate = _dateOfBirthController.text.trim().isNotEmpty;
    final hasAllNames = _hasAllNameField();
    final isActionLocked = _isActionLocked();
    final isSearchEnabled =
        (hasAllNames || hasDate) && !widget.isLoading && !isActionLocked;
    final isClearEnabled =
        _hasAnyCriteria() && !widget.isLoading && !isActionLocked;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        OutlinedButton.icon(
          onPressed: isClearEnabled ? _clearSearch : null,
          icon: const Icon(Icons.refresh_rounded, size: 14),
          label: Text(l10n.clear),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            side: const BorderSide(color: AppColors.border),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(112, AppDimensions.minTouchTarget),
            textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
          ),
        ),
        ElevatedButton.icon(
          onPressed: isSearchEnabled ? _performSearch : null,
          icon: const Icon(Icons.search_rounded, size: 14),
          label: Text(l10n.search),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.bleuArdoise,
            foregroundColor: AppColors.textOnDark,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(112, AppDimensions.minTouchTarget),
            textStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.brSm),
            disabledBackgroundColor: AppColors.stateDisabled,
            disabledForegroundColor: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  void _onFieldChanged() {
    setState(() {});
  }

  void _performSearch() {
    if (_isActionLocked()) return;
    if (widget.isLoading) return;

    final hasDate = _dateOfBirthController.text.trim().isNotEmpty;
    final hasAllNames = _hasAllNameField();

    if (!hasAllNames && !hasDate) return;

    _markActionTriggered();
    widget.dispatch(
      StandardSearchCommand(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        surname: _surnameController.text.trim(),
        dateOfBirth: _dateOfBirthController.text.trim(),
        status: widget.status,
      ),
    );
  }

  bool _hasAllNameField() {
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _surnameController.text.trim().isNotEmpty;
  }

  bool _hasAnyCriteria() {
    return _firstNameController.text.trim().isNotEmpty ||
        _lastNameController.text.trim().isNotEmpty ||
        _surnameController.text.trim().isNotEmpty ||
        _dateOfBirthController.text.trim().isNotEmpty;
  }

  void _clearSearch() {
    if (_isActionLocked()) return;
    if (widget.isLoading) return;

    _firstNameController.clear();
    _lastNameController.clear();
    _surnameController.clear();
    _dateOfBirthController.clear();
    setState(() {});

    _markActionTriggered();
    widget.dispatch(StandardSearchCommand(status: widget.status));
  }

  bool _isActionLocked() {
    final lastActionAt = _lastActionAt;
    if (lastActionAt == null) {
      return false;
    }
    return DateTime.now().difference(lastActionAt) < AppMotion.actionCooldown;
  }

  void _markActionTriggered() {
    _lastActionAt = DateTime.now();
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      _dateOfBirthController.text =
          '${date.year}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
      _onFieldChanged();
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }
}
