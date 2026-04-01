import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/enrollment_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_compact_layout.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_title.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/search_form/search_form_wide_layout.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class SearchForm extends StatefulWidget {
  const SearchForm({super.key});

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  Timer? _searchDebounce;

  static const String _defaultStatus = 'PRE_REGISTERED';
  static const String _defaultAcademicYearId = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
          final title = SearchFormTitle(label: l10n.searchStudents);
          final actions = _buildActionButtons(context, l10n);

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
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppLocalizations l10n) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: _performSearch,
          icon: const Icon(Icons.search_rounded, size: 14),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
        const SizedBox(width: 6),
        OutlinedButton.icon(
          onPressed: _clearSearch,
          icon: const Icon(Icons.refresh_rounded, size: 14),
          label: Text(l10n.clear),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.textSecondaryColor,
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            minimumSize: const Size(112, 40),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
        ),
      ],
    );
  }

  void _onFieldChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), _performSearch);
  }

  void _performSearch() {
    final hasDate = _dateOfBirthController.text.trim().isNotEmpty;
    final hasAnyName = _hasAnyNameField();

    if (!hasAnyName && !hasDate) {
      return;
    }

    if (hasAnyName && hasDate) {
      context.read<EnrollmentBloc>().add(
        EnrollmentSummariesByStudentNamesAndDateOfBirthRequested(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          surname: _surnameController.text.trim(),
          dateOfBirth: _dateOfBirthController.text.trim(),
          status: _defaultStatus,
          academicYearId: _defaultAcademicYearId,
        ),
      );
      return;
    }

    if (hasAnyName) {
      context.read<EnrollmentBloc>().add(
        EnrollmentSummariesByStudentNameRequested(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          surname: _surnameController.text.trim(),
          status: _defaultStatus,
          academicYearId: _defaultAcademicYearId,
        ),
      );
      return;
    }

    context.read<EnrollmentBloc>().add(
      EnrollmentSummariesByDateOfBirthRequested(
        dateOfBirth: _dateOfBirthController.text.trim(),
        status: _defaultStatus,
        academicYearId: _defaultAcademicYearId,
      ),
    );
  }

  bool _hasAnyNameField() {
    return _firstNameController.text.trim().isNotEmpty ||
        _lastNameController.text.trim().isNotEmpty ||
        _surnameController.text.trim().isNotEmpty;
  }

  void _clearSearch() {
    _firstNameController.clear();
    _lastNameController.clear();
    _surnameController.clear();
    _dateOfBirthController.clear();

    context.read<EnrollmentBloc>().add(
      const EnrollmentSummariesRequested(
        status: _defaultStatus,
        academicYearId: _defaultAcademicYearId,
      ),
    );
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
          '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
      _onFieldChanged();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }
}
