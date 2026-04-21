import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/widgets/eteelo_validation_button.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/academic_info/dropdown_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/form_field_label.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/input_decoration.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_title.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ReRegistrationAcademicOption {
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String label;

  const ReRegistrationAcademicOption({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.label,
  });

  String get key => '$schoolLevelGroupId::$schoolLevelId';
}

class ReRegistrationSearchRequest {
  final String firstName;
  final String lastName;
  final String surname;
  final String schoolLevelGroupId;
  final String schoolLevelId;

  const ReRegistrationSearchRequest({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
  });
}

class ReRegistrationSearchForm extends StatefulWidget {
  final List<ReRegistrationAcademicOption> options;
  final bool isLoading;
  final ValueChanged<ReRegistrationSearchRequest> onSearch;

  const ReRegistrationSearchForm({
    super.key,
    required this.options,
    required this.isLoading,
    required this.onSearch,
  });

  @override
  State<ReRegistrationSearchForm> createState() =>
      _ReRegistrationSearchFormState();
}

class _ReRegistrationSearchFormState extends State<ReRegistrationSearchForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();
  String? _selectedAcademicOptionKey;
  bool _showValidationHints = false;

  @override
  void didUpdateWidget(covariant ReRegistrationSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sanitizeSelectedKey();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uniqueOptions = _buildUniqueOptions();
    final hasOptions = uniqueOptions.isNotEmpty;
    final selectedKey =
        uniqueOptions.any((option) => option.key == _selectedAcademicOptionKey)
        ? _selectedAcademicOptionKey
        : null;
    final canSearch = _canSearch(hasOptions: hasOptions, selectedKey: selectedKey);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SearchFormTitle(label: l10n.subMenuReRegistrations),
          const SizedBox(height: 6),
          Text(
            l10n.reRegistrationSearchHint,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildTextField(
                controller: _firstNameController,
                label: l10n.firstName,
                icon: Icons.person_outline_rounded,
              ),
              _buildTextField(
                controller: _lastNameController,
                label: l10n.lastName,
                icon: Icons.badge_outlined,
              ),
              _buildTextField(
                controller: _surnameController,
                label: l10n.surname,
                icon: Icons.account_circle_outlined,
              ),
              DropdownField(
                key: ValueKey<String>(
                  'academic-option-${selectedKey ?? 'none'}-${uniqueOptions.length}',
                ),
                width: 290,
                label: '${l10n.targetCycleLabel} / ${l10n.targetLevelLabel}',
                helpMessage: l10n.reRegistrationAcademicInfoHelp,
                value: selectedKey,
                enabled: !widget.isLoading,
                errorText:
                    _showValidationHints && !_hasRequiredNames() && selectedKey == null
                    ? l10n.requiredFieldError(
                        '${l10n.targetCycleLabel} / ${l10n.targetLevelLabel}',
                      )
                    : null,
                items: uniqueOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.key,
                        child: Text(
                          option.label,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  setState(() => _selectedAcademicOptionKey = value);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 170,
                child: EteeloValidationButton(
                  onPressed: canSearch ? _submit : null,
                  label: l10n.search,
                  isLoading: widget.isLoading,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _searchAvailabilityMessage(
                    l10n: l10n,
                    hasOptions: hasOptions,
                    selectedKey: selectedKey,
                  ),
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: 240,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FormFieldLabel(
            label: label,
            requiredField: false,
            helpMessage: l10n.enterFieldHint(label),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            enabled: !widget.isLoading,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.words,
            inputFormatters: const [FirstLetterUppercaseTextInputFormatter()],
            onChanged: (_) => _onFieldChanged(),
            decoration: buildInputDecoration(
              hintText: l10n.enterFieldHint(label),
              errorText:
                  _showValidationHints &&
                      !_hasAcademicCriteria() &&
                      controller.text.trim().isEmpty
                  ? l10n.requiredFieldError(label)
                  : null,
              prefixIcon: Icon(
                icon,
                size: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<ReRegistrationAcademicOption> _buildUniqueOptions() {
    final byKey = <String, ReRegistrationAcademicOption>{};
    for (final option in widget.options) {
      byKey.putIfAbsent(option.key, () => option);
    }
    return byKey.values.toList(growable: false);
  }

  void _sanitizeSelectedKey() {
    final selectedKey = _selectedAcademicOptionKey;
    if (selectedKey == null) return;

    final stillExists = _buildUniqueOptions().any(
      (option) => option.key == selectedKey,
    );

    if (!stillExists && mounted) {
      setState(() => _selectedAcademicOptionKey = null);
    }
  }

  void _onFieldChanged() {
    if (_showValidationHints) {
      setState(() {
        _showValidationHints = false;
      });
    }
  }

  bool _hasRequiredNames() {
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _surnameController.text.trim().isNotEmpty;
  }

  bool _hasAcademicCriteria() {
    return _selectedAcademicOptionKey != null;
  }

  bool _canSearch({required bool hasOptions, required String? selectedKey}) {
    final hasAcademicCriteria = selectedKey != null;
    final hasNameCriteria = _hasRequiredNames();
    return !widget.isLoading && (hasNameCriteria || hasAcademicCriteria);
  }

  String _searchAvailabilityMessage({
    required AppLocalizations l10n,
    required bool hasOptions,
    required String? selectedKey,
  }) {
    if (widget.isLoading) {
      return '${l10n.search}...';
    }
    if (!hasOptions && !_hasRequiredNames()) {
      return l10n.reRegistrationSearchNoOptions;
    }
    if (!_hasRequiredNames() && selectedKey == null) {
      return l10n.reRegistrationSearchNeedCriteria;
    }
    return l10n.reRegistrationSearchReady;
  }

  void _submit() {
    final uniqueOptions = _buildUniqueOptions();
    final selectedKey =
        uniqueOptions.any((option) => option.key == _selectedAcademicOptionKey)
        ? _selectedAcademicOptionKey
        : null;

    if (!_canSearch(hasOptions: uniqueOptions.isNotEmpty, selectedKey: selectedKey)) {
      setState(() => _showValidationHints = true);
      return;
    }

    final selectedOption = uniqueOptions
        .where((option) => option.key == selectedKey)
        .firstOrNull;

    widget.onSearch(
      ReRegistrationSearchRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        surname: _surnameController.text.trim(),
        schoolLevelGroupId: selectedOption?.schoolLevelGroupId ?? '',
        schoolLevelId: selectedOption?.schoolLevelId ?? '',
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }
}
