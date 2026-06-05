import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_form_compact_layout.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_search_form_wide_layout.dart';

class FacturationLevelOption {
  final String schoolLevelGroupId;
  final String schoolLevelId;
  final String label;

  const FacturationLevelOption({
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
    required this.label,
  });

  String get key => '$schoolLevelGroupId::$schoolLevelId';
}

class FacturationSearchRequest {
  final String firstName;
  final String lastName;
  final String surname;
  final String schoolLevelGroupId;
  final String schoolLevelId;

  const FacturationSearchRequest({
    required this.firstName,
    required this.lastName,
    required this.surname,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
  });
}

class FacturationSearchForm extends StatefulWidget {
  final List<FacturationLevelOption> options;
  final bool isLoading;
  final ValueChanged<FacturationSearchRequest> onSearch;

  const FacturationSearchForm({
    super.key,
    required this.options,
    required this.isLoading,
    required this.onSearch,
  });

  @override
  State<FacturationSearchForm> createState() => _FacturationSearchFormState();
}

class _FacturationSearchFormState extends State<FacturationSearchForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();
  String? _selectedLevelKey;

  @override
  void didUpdateWidget(covariant FacturationSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    final key = _selectedLevelKey;
    if (key != null &&
        !widget.options.any((option) => option.key == key) &&
        mounted) {
      setState(() => _selectedLevelKey = null);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  bool _hasAllNames() =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _surnameController.text.trim().isNotEmpty;

  bool _hasLevel() =>
      _selectedLevelKey != null &&
      widget.options.any((option) => option.key == _selectedLevelKey);

  bool get _canSearch => !widget.isLoading && (_hasAllNames() || _hasLevel());

  List<FacturationLevelOption> get _uniqueOptions {
    final seen = <String>{};
    return widget.options
        .where((option) => seen.add(option.key))
        .toList(growable: false);
  }

  void _submit() {
    if (!_canSearch) return;

    final selectedOption = _uniqueOptions
        .where((option) => option.key == _selectedLevelKey)
        .firstOrNull;

    widget.onSearch(
      FacturationSearchRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        surname: _surnameController.text.trim(),
        schoolLevelGroupId: selectedOption?.schoolLevelGroupId ?? '',
        schoolLevelId: selectedOption?.schoolLevelId ?? '',
      ),
    );
  }

  void _reset() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _surnameController.clear();
      _selectedLevelKey = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = _uniqueOptions;
    final selectedKey = options.any((option) => option.key == _selectedLevelKey)
        ? _selectedLevelKey
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: AppElevation.surface3.copyWith(
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final isWide = constraints.maxWidth >= AppBreakpoints.formWideMin;
          final isMedium = constraints.maxWidth >= AppBreakpoints.formMediumMin;
          final columns = isMedium ? 3 : 1;

          final title = _SearchFormTitle(label: l10n.facturationSearchTitle);
          final description = _SearchFormDescription(
            label: l10n.facturationSearchHint,
          );
          final levelDropdown = _buildLevelDropdown(
            l10n: l10n,
            options: options,
            selectedKey: selectedKey,
          );
          final actions = _buildActions(l10n);

          if (isWide) {
            return FacturationSearchFormWideLayout(
              title: title,
              description: description,
              spacing: spacing,
              firstNameController: _firstNameController,
              lastNameController: _lastNameController,
              surnameController: _surnameController,
              firstNameLabel: l10n.firstName,
              lastNameLabel: l10n.lastName,
              surnameLabel: l10n.surname,
              levelLabel: l10n.targetLevelLabel,
              isLoading: widget.isLoading,
              levelDropdown: levelDropdown,
              actions: actions,
            );
          }

          final calculatedWidth =
              (constraints.maxWidth - ((columns - 1) * spacing)) / columns;
          final fieldWidth = calculatedWidth.clamp(170.0, 360.0).toDouble();

          return FacturationSearchFormCompactLayout(
            title: title,
            description: description,
            spacing: spacing,
            fieldWidth: fieldWidth,
            availableWidth: constraints.maxWidth,
            firstNameController: _firstNameController,
            lastNameController: _lastNameController,
            surnameController: _surnameController,
            firstNameLabel: l10n.firstName,
            lastNameLabel: l10n.lastName,
            surnameLabel: l10n.surname,
            isLoading: widget.isLoading,
            levelDropdown: levelDropdown,
            actions: actions,
          );
        },
      ),
    );
  }

  Widget _buildLevelDropdown({
    required AppLocalizations l10n,
    required List<FacturationLevelOption> options,
    required String? selectedKey,
  }) {
    return DropdownButtonFormField<String>(
      key: ValueKey('level-$selectedKey-${options.length}'),
      initialValue: selectedKey,
      isExpanded: true,
      isDense: true,
      style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.textSecondary,
      ),
      decoration: InputDecoration(
        labelText: '${l10n.targetCycleLabel} / ${l10n.targetLevelLabel}',
        labelStyle: const TextStyle(fontSize: 12),
        isDense: true,
        filled: true,
        fillColor: AppColors.surfaceAlt,
        prefixIcon: const Icon(
          Icons.school_outlined,
          size: 16,
          color: AppColors.textSecondary,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 34),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.brSm,
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.key,
              child: Text(option.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: widget.isLoading || options.isEmpty
          ? null
          : (value) => setState(() => _selectedLevelKey = value),
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingS,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        EteeloButton.primary(
          onPressed: _canSearch ? _submit : null,
          icon: Icons.search_rounded,
          label: l10n.search,
          isLoading: widget.isLoading,
        ),
        EteeloButton.ghost(
          onPressed: widget.isLoading ? null : _reset,
          icon: Icons.refresh_rounded,
          label: l10n.clear,
        ),
      ],
    );
  }
}

class _SearchFormTitle extends StatelessWidget {
  final String label;

  const _SearchFormTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary),
    );
  }
}

class _SearchFormDescription extends StatelessWidget {
  final String label;

  const _SearchFormDescription({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
    );
  }
}
