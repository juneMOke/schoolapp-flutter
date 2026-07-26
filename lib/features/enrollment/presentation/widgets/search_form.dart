import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_responsive_view.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_status_filter_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SearchForm extends StatefulWidget {
  final String academicYearId;
  final String status;
  final bool isLoading;
  final EnrollmentSearchDispatcher dispatch;
  final bool showStatusFilter;
  final ValueChanged<String>? onStatusChanged;
  final String? subtitle;

  const SearchForm({
    super.key,
    required this.academicYearId,
    required this.status,
    required this.isLoading,
    required this.dispatch,
    this.showStatusFilter = false,
    this.onStatusChanged,
    this.subtitle,
  });

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  DateTime? _lastSearchActionAt;
  DateTime? _lastClearActionAt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusDropdown = widget.showStatusFilter
        ? SearchFormStatusFilterField(
            selectedStatus: widget.status,
            onChanged: _handleStatusChanged,
          )
        : null;

    return SearchFormResponsiveView(
      title: l10n.searchStudents,
      subtitle: widget.subtitle,
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
      return [...fields, statusDropdown];
    }

    return fields;
  }

  Widget _buildActionButtons(AppLocalizations l10n) {
    final hasDate = _selectedDateOfBirth != null;
    final hasAllNames = _hasAllNameField();
    final isSearchEnabled =
        (hasAllNames || hasDate) &&
        !widget.isLoading &&
        !_isLocked(_lastSearchActionAt);
    final isClearEnabled =
        _hasAnyCriteria() &&
        !widget.isLoading &&
        !_isLocked(_lastClearActionAt);

    final clearButton = EteeloButton.ghost(
      onPressed: isClearEnabled ? _clearSearch : null,
      icon: Icons.refresh_rounded,
      label: l10n.clear,
    );
    final searchButton = EteeloButton.primary(
      onPressed: isSearchEnabled ? _performSearch : null,
      icon: Icons.search_rounded,
      label: l10n.search,
      isLoading: widget.isLoading,
    );

    return LayoutBuilder(
      builder: (_, constraints) {
        final stacked = constraints.maxWidth < AppBreakpoints.dataTableCardsMax;

        if (stacked) {
          return Row(
            children: [
              Expanded(child: clearButton),
              const SizedBox(width: AppSpacing.gridGap),
              Expanded(child: searchButton),
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            clearButton,
            const SizedBox(width: AppSpacing.gridGap),
            searchButton,
          ],
        );
      },
    );
  }

  void _onFieldChanged() {
    setState(() {});
  }

  void _performSearch() {
    if (_isLocked(_lastSearchActionAt)) return;
    if (widget.isLoading) return;

    final hasDate = _selectedDateOfBirth != null;
    final hasAllNames = _hasAllNameField();

    if (!hasAllNames && !hasDate) return;

    _lastSearchActionAt = DateTime.now();
    widget.dispatch(_buildCriteriaCommand(widget.status));
  }

  /// Reste sur le statut choisi mais préserve les critères nom/date déjà
  /// saisis dans ce formulaire (le changement de statut ne doit pas faire
  /// perdre une recherche en cours).
  void _handleStatusChanged(String newStatus) {
    widget.onStatusChanged?.call(newStatus);

    final hasDate = _selectedDateOfBirth != null;
    final hasAllNames = _hasAllNameField();

    widget.dispatch(
      hasAllNames || hasDate
          ? _buildCriteriaCommand(newStatus)
          : StandardSearchCommand(status: newStatus),
    );
  }

  StandardSearchCommand _buildCriteriaCommand(String status) {
    return StandardSearchCommand(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      surname: _surnameController.text.trim(),
      dateOfBirth: _formattedDateOfBirth(),
      status: status,
    );
  }

  // Format ISO 8601 pour l'API (yyyy-MM-dd).
  String _formattedDateOfBirth() {
    final date = _selectedDateOfBirth;
    if (date == null) return '';
    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
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
    if (_isLocked(_lastClearActionAt)) return;
    if (widget.isLoading) return;

    _firstNameController.clear();
    _lastNameController.clear();
    _surnameController.clear();
    setState(() => _selectedDateOfBirth = null);

    _lastClearActionAt = DateTime.now();
    widget.dispatch(StandardSearchCommand(status: widget.status));
  }

  bool _isLocked(DateTime? lastActionAt) {
    if (lastActionAt == null) {
      return false;
    }
    return DateTime.now().difference(lastActionAt) < AppMotion.actionCooldown;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }
}
