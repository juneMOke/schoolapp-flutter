import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/first_letter_uppercase_text_input_formatter.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/forms/wizard_fields_grid.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        WizardFieldsGrid(
          fields: [
            WizardGridField(
              _AddressSelectField(
                label: l10n.city,
                options: cityOptions,
                value: cityValue,
                errorText: cityErrorText,
                enabled: isEditable && !isCatalogLoading,
                emptyOptionsHint: cityHint,
                onChanged: onCityChanged,
              ),
            ),
            WizardGridField(
              _AddressSelectField(
                label: l10n.district,
                options: districtOptions,
                value: districtValue,
                errorText: districtErrorText,
                enabled: isEditable && !isCatalogLoading && cityValue != null,
                emptyOptionsHint: districtHint,
                onChanged: onDistrictChanged,
              ),
            ),
            WizardGridField(
              _AddressSelectField(
                label: l10n.municipality,
                options: municipalityOptions,
                value: municipalityValue,
                errorText: municipalityErrorText,
                enabled:
                    isEditable && !isCatalogLoading && districtValue != null,
                emptyOptionsHint: municipalityHint,
                onChanged: onMunicipalityChanged,
              ),
            ),
            WizardGridField(
              _AddressSelectField(
                label: l10n.neighborhood,
                options: neighborhoodOptions,
                value: neighborhoodValue,
                errorText: addressErrorText,
                enabled:
                    isEditable &&
                    !isCatalogLoading &&
                    municipalityValue != null,
                emptyOptionsHint: neighborhoodHint,
                onChanged: onNeighborhoodChanged,
              ),
            ),
            WizardGridField(
              EteeloTextInput(
                label: l10n.addressComplementary,
                controller: additionalAddressController,
                required: false,
                placeholder: l10n.addressComplementaryPlaceholder,
                readOnly: !isEditable,
                inputFormatters: const [
                  FirstLetterUppercaseTextInputFormatter(),
                ],
              ),
              fullWidth: true,
            ),
          ],
        ),
        if (isCatalogLoading) ...[
          const SizedBox(height: 10),
          const LinearProgressIndicator(minHeight: 2),
        ],
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
                        color: AppColors.textOnDark,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isLoading ? l10n.savingAddress : l10n.saveAddress),
              style: FilledButton.styleFrom(
                backgroundColor: canSave ? AppColors.terreCuite : null,
                foregroundColor: AppColors.textOnDark,
                elevation: 0,
                minimumSize: const Size(164, 44),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.brMd,
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
  }
}

/// Champ de sélection en cascade (Ville → District → Commune → Quartier).
///
/// Reprend exactement le comportement d'AddressDropdownField (valeur résolue,
/// état `enabled`, errorText, indice « aucune option ») sans largeur propre :
/// la largeur est gérée par [WizardFieldsGrid].
class _AddressSelectField extends StatelessWidget {
  final String label;
  final List<String> options;
  final String? value;
  final String? errorText;
  final bool enabled;
  final String? emptyOptionsHint;
  final ValueChanged<String?> onChanged;

  const _AddressSelectField({
    required this.label,
    required this.options,
    required this.value,
    required this.errorText,
    required this.enabled,
    required this.emptyOptionsHint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedValue = value != null && options.contains(value)
        ? value
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EteeloSelectInput<String>(
          value: selectedValue,
          label: label,
          required: true,
          errorText: errorText,
          enabled: enabled && options.isNotEmpty,
          placeholder: l10n.selectPlaceholderChoose,
          menuMaxHeight: 320,
          items: options
              .map(
                (option) =>
                    EteeloSelectItem<String>(value: option, label: option),
              )
              .toList(growable: false),
          onChanged: onChanged,
        ),
        if (enabled && options.isEmpty && emptyOptionsHint != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: AppTheme.textSecondaryColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  emptyOptionsHint!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
