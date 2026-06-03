import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_listing_page_contracts.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_responsive_view.dart';
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

class ReRegistrationSearchForm extends StatefulWidget {
  final List<ReRegistrationAcademicOption> options;
  final bool isLoading;
  final EnrollmentSearchDispatcher dispatch;

  const ReRegistrationSearchForm({
    super.key,
    required this.options,
    required this.isLoading,
    required this.dispatch,
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

  @override
  void didUpdateWidget(covariant ReRegistrationSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sanitizeSelectedKey();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uniqueOptions = _buildUniqueOptions();
    final selectedKey =
        uniqueOptions.any((o) => o.key == _selectedAcademicOptionKey)
        ? _selectedAcademicOptionKey
        : null;
    final canSearch =
        !widget.isLoading && (_hasRequiredNames() || selectedKey != null);

    return SearchFormResponsiveView(
      title: l10n.subMenuReRegistrations,
      subtitle: l10n.reRegistrationSearchHint,
      icon: Icons.manage_search_rounded,
      fields: [
        ..._buildNameFields(l10n),
        _buildAcademicDropdown(
          l10n: l10n,
          uniqueOptions: uniqueOptions,
          selectedKey: selectedKey,
        ),
      ],
      actions: _buildActions(l10n: l10n, canSearch: canSearch),
    );
  }

  // ─── Builders ─────────────────────────────────────────────────────────────

  List<Widget> _buildNameFields(AppLocalizations l10n) => [
    SearchFormInput(
      controller: _firstNameController,
      label: l10n.firstName,
      prefixIcon: const Icon(Icons.person_outline_rounded, size: 16),
      onChanged: (_) => setState(() {}),
    ),
    SearchFormInput(
      controller: _lastNameController,
      label: l10n.lastName,
      prefixIcon: const Icon(Icons.badge_outlined, size: 16),
      onChanged: (_) => setState(() {}),
    ),
    SearchFormInput(
      controller: _surnameController,
      label: l10n.surname,
      prefixIcon: const Icon(Icons.account_circle_outlined, size: 16),
      onChanged: (_) => setState(() {}),
    ),
  ];

  Widget _buildAcademicDropdown({
    required AppLocalizations l10n,
    required List<ReRegistrationAcademicOption> uniqueOptions,
    required String? selectedKey,
  }) {
    final selectItems = uniqueOptions
        .map((o) => EteeloSelectItem<String>(value: o.key, label: o.label))
        .toList(growable: false);

    return EteeloSelectInput<String>(
      key: ValueKey<String>(
        'academic-option-${selectedKey ?? 'none'}-${uniqueOptions.length}',
      ),
      label: '${l10n.targetCycleLabel} / ${l10n.targetLevelLabel}',
      placeholder: l10n.selectPlaceholderChoose,
      value: selectedKey,
      items: selectItems,
      enabled: !widget.isLoading && uniqueOptions.isNotEmpty,
      panelMode: EteeloSelectPanelMode.popover,
      onChanged: (value) => setState(() => _selectedAcademicOptionKey = value),
    );
  }

  Widget _buildActions({
    required AppLocalizations l10n,
    required bool canSearch,
  }) {
    final isClearEnabled = _hasAnyCriteria() && !widget.isLoading;

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
          onPressed: canSearch ? _submit : null,
          icon: widget.isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.textOnDark,
                  ),
                )
              : const Icon(Icons.search_rounded, size: 14),
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

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<ReRegistrationAcademicOption> _buildUniqueOptions() {
    final byKey = <String, ReRegistrationAcademicOption>{};
    for (final o in widget.options) {
      byKey.putIfAbsent(o.key, () => o);
    }
    return byKey.values.toList(growable: false);
  }

  void _sanitizeSelectedKey() {
    final key = _selectedAcademicOptionKey;
    if (key == null) {
      return;
    }
    final stillExists = _buildUniqueOptions().any((o) => o.key == key);
    if (!stillExists && mounted) {
      setState(() => _selectedAcademicOptionKey = null);
    }
  }

  bool _hasRequiredNames() =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _surnameController.text.trim().isNotEmpty;

  bool _hasAnyCriteria() =>
      _firstNameController.text.trim().isNotEmpty ||
      _lastNameController.text.trim().isNotEmpty ||
      _surnameController.text.trim().isNotEmpty ||
      _selectedAcademicOptionKey != null;

  void _clearSearch() {
    if (widget.isLoading) return;
    _firstNameController.clear();
    _lastNameController.clear();
    _surnameController.clear();
    setState(() => _selectedAcademicOptionKey = null);
  }

  void _submit() {
    final uniqueOptions = _buildUniqueOptions();
    final selectedKey =
        uniqueOptions.any((o) => o.key == _selectedAcademicOptionKey)
        ? _selectedAcademicOptionKey
        : null;
    if (widget.isLoading || (!_hasRequiredNames() && selectedKey == null)) {
      return;
    }
    final selectedOption = uniqueOptions
        .where((o) => o.key == selectedKey)
        .firstOrNull;
    widget.dispatch(
      AcademicInfoSearchCommand(
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
