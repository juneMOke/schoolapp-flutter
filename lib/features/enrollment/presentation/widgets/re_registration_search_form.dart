import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();
  String? _selectedAcademicOptionKey;

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
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.subMenuReRegistrations,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor,
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
                ),
                _buildTextField(
                  controller: _lastNameController,
                  label: l10n.lastName,
                ),
                _buildTextField(
                  controller: _surnameController,
                  label: l10n.surname,
                ),
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField<String>(
                    key: ValueKey<String>(
                      'academic-option-${selectedKey ?? 'none'}-${uniqueOptions.length}',
                    ),
                    initialValue: selectedKey,
                    decoration: InputDecoration(
                      labelText:
                          '${l10n.targetCycleLabel} / ${l10n.targetLevelLabel}',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
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
                        .toList(),
                    onChanged: widget.isLoading
                        ? null
                        : (value) {
                            setState(() => _selectedAcademicOptionKey = value);
                          },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n.requiredFieldError(
                          '${l10n.targetCycleLabel} / ${l10n.targetLevelLabel}',
                        );
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: (!widget.isLoading && hasOptions) ? _submit : null,
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: Text(l10n.search),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(140, 42),
                  ),
                ),
                if (!hasOptions) ...[
                  const SizedBox(width: 10),
                  const Flexible(
                    child: Text(
                      'Aucun niveau/cycle disponible pour la recherche.',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: 220,
      child: TextFormField(
        controller: controller,
        enabled: !widget.isLoading,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return l10n.requiredFieldError(label);
          }
          return null;
        },
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

  void _submit() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final selectedKey = _selectedAcademicOptionKey;
    if (selectedKey == null) return;
    final selectedOption = _buildUniqueOptions()
        .where((option) => option.key == selectedKey)
        .firstOrNull;
    if (selectedOption == null) return;

    widget.onSearch(
      ReRegistrationSearchRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        surname: _surnameController.text.trim(),
        schoolLevelGroupId: selectedOption.schoolLevelGroupId,
        schoolLevelId: selectedOption.schoolLevelId,
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
