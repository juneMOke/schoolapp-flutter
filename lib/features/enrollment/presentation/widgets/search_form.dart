import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_responsive_view.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_status_dropdown.dart';
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

  DateTime? _selectedDateOfBirth;
  DateTime? _lastActionAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusDropdown = widget.showStatusFilter
        ? SearchFormStatusDropdown(
            selectedStatus: widget.status,
            onChanged: (value) => widget.onStatusChanged?.call(value),
          )
        : null;

    return SearchFormResponsiveView(
      title: l10n.searchStudents,
      icon: Icons.search_rounded,
      fields: _buildFields(l10n, statusDropdown),
      actions: _buildActionButtons(l10n),
    );
  }

  List<Widget> _buildFields(AppLocalizations l10n, Widget? statusDropdown) {
    final fields = <Widget>[
      EteeloTextInput(
        controller: _firstNameController,
        label: l10n.firstName,
        placeholder: l10n.firstNameExample,
        inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
        onChanged: (_) => _onFieldChanged(),
      ),
      EteeloTextInput(
        controller: _lastNameController,
        label: l10n.lastName,
        placeholder: l10n.lastNameExample,
        inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
        onChanged: (_) => _onFieldChanged(),
      ),
      EteeloTextInput(
        controller: _surnameController,
        label: l10n.surname,
        placeholder: l10n.surnameExample,
        inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
        onChanged: (_) => _onFieldChanged(),
      ),
      EteeloDateInput(
        label: l10n.dateOfBirth,
        placeholder: l10n.dateHint,
        value: _selectedDateOfBirth,
        lastDate: DateTime.now(),
        onChanged: (date) => setState(() => _selectedDateOfBirth = date),
      ),
    ];

    if (statusDropdown != null) {
      return [statusDropdown, ...fields];
    }

    return fields;
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    final hasDate = _selectedDateOfBirth != null;
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
            textStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
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
            textStyle: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
            ),
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

    final hasDate = _selectedDateOfBirth != null;
    final hasAllNames = _hasAllNameField();

    if (!hasAllNames && !hasDate) return;

    // Format ISO 8601 pour l'API (yyyy-MM-dd).
    final dateOfBirthParam = _selectedDateOfBirth != null
        ? '${_selectedDateOfBirth!.year}-'
              '${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-'
              '${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}'
        : '';

    _markActionTriggered();
    widget.dispatch(
      StandardSearchCommand(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        surname: _surnameController.text.trim(),
        dateOfBirth: dateOfBirthParam,
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
        _selectedDateOfBirth != null;
  }

  void _clearSearch() {
    if (_isActionLocked()) return;
    if (widget.isLoading) return;

    _firstNameController.clear();
    _lastNameController.clear();
    _surnameController.clear();
    setState(() => _selectedDateOfBirth = null);

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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }
}
