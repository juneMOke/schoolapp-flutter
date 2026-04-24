import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/address/address_dropdown_field.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/editable_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AddressFormContent extends StatelessWidget {
  final String? cityValue;
  final String? districtValue;
  final String? municipalityValue;
  final String? neighborhoodValue;
  final List<String> cityOptions;
  final List<String> districtOptions;
  final List<String> municipalityOptions;
  final List<String> neighborhoodOptions;
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onDistrictChanged;
  final ValueChanged<String?> onMunicipalityChanged;
  final ValueChanged<String?> onNeighborhoodChanged;
  final String? cityErrorText;
  final String? districtErrorText;
  final String? municipalityErrorText;
  final String? addressErrorText;
  final TextEditingController additionalAddressController;
  final bool showInlineSaveButton;
  final bool isLoading;
  final bool isCatalogLoading;
  final bool canSave;
  final VoidCallback onSave;
  final bool isEditable;

  const AddressFormContent({
    super.key,
    required this.cityValue,
    required this.districtValue,
    required this.municipalityValue,
    required this.neighborhoodValue,
    required this.cityOptions,
    required this.districtOptions,
    required this.municipalityOptions,
    required this.neighborhoodOptions,
    required this.onCityChanged,
    required this.onDistrictChanged,
    required this.onMunicipalityChanged,
    required this.onNeighborhoodChanged,
    required this.cityErrorText,
    required this.districtErrorText,
    required this.municipalityErrorText,
    required this.addressErrorText,
    required this.additionalAddressController,
    required this.showInlineSaveButton,
    required this.isLoading,
    required this.isCatalogLoading,
    required this.canSave,
    required this.onSave,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cityHint = cityOptions.isEmpty ? l10n.addressNoCityAvailable : null;
    final districtHint = districtOptions.isEmpty
        ? (cityValue == null
              ? l10n.addressSelectCityFirst
              : l10n.addressNoDistrictAvailable)
        : null;
    final municipalityHint = municipalityOptions.isEmpty
        ? (districtValue == null
              ? l10n.addressSelectDistrictFirst
              : l10n.addressNoMunicipalityAvailable)
        : null;
    final neighborhoodHint = neighborhoodOptions.isEmpty
        ? (municipalityValue == null
              ? l10n.addressSelectMunicipalityFirst
              : l10n.addressNoNeighborhoodAvailable)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final columns = constraints.maxWidth >= 640 ? 2 : 1;
        final fieldWidth =
            (constraints.maxWidth - (columns - 1) * spacing) / columns;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: spacing,
              runSpacing: 14,
              children: [
                AddressDropdownField(
                  width: fieldWidth,
                  label: l10n.city,
                  helpMessage: l10n.cityHelp,
                  options: cityOptions,
                  value: cityValue,
                  errorText: cityErrorText,
                  requiredField: true,
                  enabled: isEditable && !isCatalogLoading,
                  icon: Icons.location_city_outlined,
                  emptyOptionsHint: cityHint,
                  onChanged: onCityChanged,
                ),
                AddressDropdownField(
                  width: fieldWidth,
                  label: l10n.district,
                  helpMessage: l10n.districtHelp,
                  options: districtOptions,
                  value: districtValue,
                  errorText: districtErrorText,
                  requiredField: true,
                  enabled: isEditable && !isCatalogLoading && cityValue != null,
                  icon: Icons.map_outlined,
                  emptyOptionsHint: districtHint,
                  onChanged: onDistrictChanged,
                ),
                AddressDropdownField(
                  width: fieldWidth,
                  label: l10n.municipality,
                  helpMessage: l10n.municipalityHelp,
                  options: municipalityOptions,
                  value: municipalityValue,
                  errorText: municipalityErrorText,
                  requiredField: true,
                  enabled:
                      isEditable && !isCatalogLoading && districtValue != null,
                  icon: Icons.apartment_outlined,
                  emptyOptionsHint: municipalityHint,
                  onChanged: onMunicipalityChanged,
                ),
                AddressDropdownField(
                  width: fieldWidth,
                  label: l10n.neighborhood,
                  helpMessage: l10n.neighborhoodHelp,
                  options: neighborhoodOptions,
                  value: neighborhoodValue,
                  errorText: addressErrorText,
                  requiredField: true,
                  enabled:
                      isEditable &&
                      !isCatalogLoading &&
                      municipalityValue != null,
                  icon: Icons.home_work_outlined,
                  emptyOptionsHint: neighborhoodHint,
                  onChanged: onNeighborhoodChanged,
                ),
              ],
            ),
            if (isCatalogLoading) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(minHeight: 2),
            ],
            const SizedBox(height: 14),
            EditableField(
              width: constraints.maxWidth,
              label: l10n.addressComplementary,
              controller: additionalAddressController,
              requiredField: false,
              helpMessage: l10n.addressComplementaryHelp,
              hintText: l10n.addressComplementaryPlaceholder,
              readOnly: !isEditable,
            ),
            if (showInlineSaveButton) ...[
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: (isLoading || !canSave) ? null : onSave,
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    isLoading ? l10n.savingAddress : l10n.saveAddress,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: canSave ? const Color(0xFF0EA5E9) : null,
                    foregroundColor: Colors.white,
                    elevation: canSave ? 6 : 0,
                    shadowColor: const Color(
                      0xFF0EA5E9,
                    ).withValues(alpha: 0.45),
                    minimumSize: const Size(164, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
