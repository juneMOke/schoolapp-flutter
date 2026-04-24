import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_input.dart';
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 10.0;
          final isWide = constraints.maxWidth >= 1280;
          final isMedium = constraints.maxWidth >= 860;
          final columns = isMedium ? 3 : 1;

          final nameFields = _buildNameFields(l10n);
          final academicDropdown = _buildAcademicDropdown(
            l10n: l10n,
            uniqueOptions: uniqueOptions,
            selectedKey: selectedKey,
          );
          final actions = _buildActions(
            l10n: l10n,
            canSearch: canSearch,
          );

          return Column(
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
              const SizedBox(height: 10),
              if (isWide)
                _WideLayout(
                  spacing: spacing,
                  nameFields: nameFields,
                  academicDropdown: academicDropdown,
                  actions: actions,
                )
              else
                _CompactLayout(
                  spacing: spacing,
                  columns: columns,
                  availableWidth: constraints.maxWidth,
                  nameFields: nameFields,
                  academicDropdown: academicDropdown,
                  actions: actions,
                ),
            ],
          );
        },
      ),
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
    return DropdownButtonFormField<String>(
      key: ValueKey<String>(
        'academic-option-${selectedKey ?? 'none'}-${uniqueOptions.length}',
      ),
      initialValue: selectedKey,
      isExpanded: true,
      isDense: true,
      style: const TextStyle(
        fontSize: 13,
        color: AppTheme.textPrimaryColor,
      ),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        size: 18,
        color: AppTheme.textSecondaryColor,
      ),
      decoration: InputDecoration(
        labelText: '${l10n.targetCycleLabel} / ${l10n.targetLevelLabel}',
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: const Icon(Icons.school_outlined, size: 16),
        prefixIconConstraints: const BoxConstraints(minWidth: 34),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(9),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 1.4,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
      ),
      items: uniqueOptions
          .map(
            (o) => DropdownMenuItem<String>(
              value: o.key,
              child: Text(o.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: widget.isLoading || uniqueOptions.isEmpty
          ? null
          : (value) => setState(() => _selectedAcademicOptionKey = value),
    );
  }

  Widget _buildActions({
    required AppLocalizations l10n,
    required bool canSearch,
  }) {
    return ElevatedButton.icon(
      onPressed: canSearch ? _submit : null,
      icon: widget.isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.search_rounded, size: 14),
      label: Text(l10n.search),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        minimumSize: const Size(112, 40),
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        disabledBackgroundColor: Colors.grey[300],
        disabledForegroundColor: Colors.grey,
      ),
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
    if (key == null) return;
    final stillExists = _buildUniqueOptions().any((o) => o.key == key);
    if (!stillExists && mounted) setState(() => _selectedAcademicOptionKey = null);
  }

  bool _hasRequiredNames() =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _surnameController.text.trim().isNotEmpty;

  void _submit() {
    final uniqueOptions = _buildUniqueOptions();
    final selectedKey =
        uniqueOptions.any((o) => o.key == _selectedAcademicOptionKey)
        ? _selectedAcademicOptionKey
        : null;
    if (widget.isLoading || (!_hasRequiredNames() && selectedKey == null)) {
      return;
    }
    final selectedOption =
        uniqueOptions.where((o) => o.key == selectedKey).firstOrNull;
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

// ─── Layouts ──────────────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final double spacing;
  final List<Widget> nameFields;
  final Widget academicDropdown;
  final Widget actions;

  const _WideLayout({
    required this.spacing,
    required this.nameFields,
    required this.academicDropdown,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...nameFields.expand(
          (f) => [Expanded(child: f), SizedBox(width: spacing)],
        ),
        Expanded(child: academicDropdown),
        const SizedBox(width: 14),
        actions,
      ],
    );
  }
}

class _CompactLayout extends StatelessWidget {
  final double spacing;
  final int columns;
  final double availableWidth;
  final List<Widget> nameFields;
  final Widget academicDropdown;
  final Widget actions;

  const _CompactLayout({
    required this.spacing,
    required this.columns,
    required this.availableWidth,
    required this.nameFields,
    required this.academicDropdown,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final fieldWidth = ((availableWidth - (columns - 1) * spacing) / columns)
        .clamp(170.0, 360.0);

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...nameFields.map((f) => SizedBox(width: fieldWidth, child: f)),
        SizedBox(width: fieldWidth, child: academicDropdown),
        SizedBox(
          width: availableWidth,
          child: Align(alignment: Alignment.centerRight, child: actions),
        ),
      ],
    );
  }
}