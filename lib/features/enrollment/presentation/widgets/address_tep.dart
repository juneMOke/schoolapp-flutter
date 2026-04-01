import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/editable_field.dart';
import 'package:school_app_flutter/features/student/domain/entities/student_detail.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AddressStep extends StatefulWidget {
  final StudentDetail studentDetail;

  const AddressStep({super.key, required this.studentDetail});

  @override
  State<AddressStep> createState() => _AddressStepState();
}

class _AddressStepState extends State<AddressStep> {
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;
  late final TextEditingController _municipalityController;
  late final TextEditingController _neighborhoodController;
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final s = widget.studentDetail;
    _cityController         = TextEditingController(text: s.city);
    _districtController     = TextEditingController(text: s.district);
    _municipalityController = TextEditingController(text: s.municipality);
    _neighborhoodController = TextEditingController(
      text: _extractNeighborhood(s.address),
    );
    _addressController = TextEditingController(text: s.address);
  }

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    _municipalityController.dispose();
    _neighborhoodController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  static String _extractNeighborhood(String address) {
    final parts = address.split(',');
    return parts.length > 1 ? parts.first.trim() : '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppTheme.defaultPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          const spacing = 16.0;
          final columns = constraints.maxWidth >= 640 ? 2 : 1;
          final w = (constraints.maxWidth - (columns - 1) * spacing) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: 14,
            children: [
              EditableField(
                width: w,
                label: l10n.city,
                controller: _cityController,
                requiredField: true,
                helpMessage: l10n.cityHelp,
              ),
              EditableField(
                width: w,
                label: l10n.district,
                controller: _districtController,
                requiredField: true,
                helpMessage: l10n.districtHelp,
              ),
              EditableField(
                width: w,
                label: l10n.municipality,
                controller: _municipalityController,
                requiredField: true,
                helpMessage: l10n.municipalityHelp,
              ),
              EditableField(
                width: w,
                label: l10n.neighborhood,
                controller: _neighborhoodController,
                helpMessage: l10n.neighborhoodHelp,
              ),
              EditableField(
                width: constraints.maxWidth,
                label: l10n.fullAddress,
                controller: _addressController,
                requiredField: true,
                helpMessage: l10n.fullAddressHelp,
              ),
            ],
          );
        },
      ),
    );
  }
}