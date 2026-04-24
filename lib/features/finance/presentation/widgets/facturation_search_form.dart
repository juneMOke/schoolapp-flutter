import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

// ─── Transfer objects ─────────────────────────────────────────────────────────

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

// ─── Widget ───────────────────────────────────────────────────────────────────

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
    // Nettoie la sélection si l'option n'existe plus dans la nouvelle liste.
    final key = _selectedLevelKey;
    if (key != null &&
        !widget.options.any((o) => o.key == key) &&
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

  // ─── Helpers ────────────────────────────────────────────────────────────────

  bool _hasAllNames() =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _surnameController.text.trim().isNotEmpty;

  bool _hasLevel() =>
      _selectedLevelKey != null &&
      widget.options.any((o) => o.key == _selectedLevelKey);

  bool get _canSearch =>
      !widget.isLoading && (_hasAllNames() || _hasLevel());

  List<FacturationLevelOption> get _uniqueOptions {
    final seen = <String>{};
    return widget.options.where((o) => seen.add(o.key)).toList(growable: false);
  }

  void _submit() {
    if (!_canSearch) return;
    final options = _uniqueOptions;
    final selectedOption =
        options.where((o) => o.key == _selectedLevelKey).firstOrNull;
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

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = _uniqueOptions;
    final selectedKey =
        options.any((o) => o.key == _selectedLevelKey) ? _selectedLevelKey : null;

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
          final levelDropdown = _buildLevelDropdown(
            l10n: l10n,
            options: options,
            selectedKey: selectedKey,
          );
          final searchButton = _buildSearchButton(l10n);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _FormTitle(label: l10n.facturationSearchTitle),
              const SizedBox(height: 6),
              Text(
                l10n.facturationSearchHint,
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
                  levelDropdown: levelDropdown,
                  searchButton: searchButton,
                )
              else
                _CompactLayout(
                  spacing: spacing,
                  columns: columns,
                  availableWidth: constraints.maxWidth,
                  nameFields: nameFields,
                  levelDropdown: levelDropdown,
                  searchButton: searchButton,
                ),
            ],
          );
        },
      ),
    );
  }

  // ─── Sub-builders ────────────────────────────────────────────────────────────

  List<Widget> _buildNameFields(AppLocalizations l10n) => [
    _FacturationTextField(
      controller: _firstNameController,
      label: l10n.firstName,
      prefixIcon: const Icon(Icons.person_outline_rounded, size: 16),
      onChanged: (_) => setState(() {}),
    ),
    _FacturationTextField(
      controller: _lastNameController,
      label: l10n.lastName,
      prefixIcon: const Icon(Icons.badge_outlined, size: 16),
      onChanged: (_) => setState(() {}),
    ),
    _FacturationTextField(
      controller: _surnameController,
      label: l10n.surname,
      prefixIcon: const Icon(Icons.account_circle_outlined, size: 16),
      onChanged: (_) => setState(() {}),
    ),
  ];

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      items: options
          .map(
            (o) => DropdownMenuItem<String>(
              value: o.key,
              child: Text(o.label, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(growable: false),
      onChanged: widget.isLoading || options.isEmpty
          ? null
          : (value) => setState(() => _selectedLevelKey = value),
    );
  }

  Widget _buildSearchButton(AppLocalizations l10n) {
    return ElevatedButton.icon(
      onPressed: _canSearch ? _submit : null,
      icon: widget.isLoading
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
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
}

// ─── Layouts ──────────────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  final double spacing;
  final List<Widget> nameFields;
  final Widget levelDropdown;
  final Widget searchButton;

  const _WideLayout({
    required this.spacing,
    required this.nameFields,
    required this.levelDropdown,
    required this.searchButton,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...nameFields.expand(
          (f) => [Expanded(child: f), SizedBox(width: spacing)],
        ),
        Expanded(child: levelDropdown),
        const SizedBox(width: 14),
        searchButton,
      ],
    );
  }
}

class _CompactLayout extends StatelessWidget {
  final double spacing;
  final int columns;
  final double availableWidth;
  final List<Widget> nameFields;
  final Widget levelDropdown;
  final Widget searchButton;

  const _CompactLayout({
    required this.spacing,
    required this.columns,
    required this.availableWidth,
    required this.nameFields,
    required this.levelDropdown,
    required this.searchButton,
  });

  @override
  Widget build(BuildContext context) {
    final fieldWidth =
        ((availableWidth - (columns - 1) * spacing) / columns).clamp(170.0, 360.0);

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ...nameFields.map((f) => SizedBox(width: fieldWidth, child: f)),
        SizedBox(width: fieldWidth, child: levelDropdown),
        SizedBox(
          width: availableWidth,
          child: Align(alignment: Alignment.centerRight, child: searchButton),
        ),
      ],
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

class _FormTitle extends StatelessWidget {
  final String label;

  const _FormTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }
}

class _FacturationTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final Widget prefixIcon;
  final ValueChanged<String>? onChanged;

  const _FacturationTextField({
    required this.controller,
    required this.label,
    required this.prefixIcon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        prefixIcon: prefixIcon,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
    );
  }
}
