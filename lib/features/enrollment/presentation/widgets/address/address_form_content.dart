import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/personal_info/editable_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class AddressFormContent extends StatelessWidget {
  final TextEditingController cityController;
  final TextEditingController districtController;
  final TextEditingController municipalityController;
  final TextEditingController addressController;
  final String? cityErrorText;
  final String? districtErrorText;
  final String? municipalityErrorText;
  final String? addressErrorText;
  final bool showInlineSaveButton;
  final bool isLoading;
  final bool canSave;
  final VoidCallback onSave;

  const AddressFormContent({
    super.key,
    required this.cityController,
    required this.districtController,
    required this.municipalityController,
    required this.addressController,
    required this.cityErrorText,
    required this.districtErrorText,
    required this.municipalityErrorText,
    required this.addressErrorText,
    required this.showInlineSaveButton,
    required this.isLoading,
    required this.canSave,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
                EditableField(
                  width: fieldWidth,
                  label: l10n.city,
                  controller: cityController,
                  requiredField: true,
                  helpMessage: l10n.cityHelp,
                  errorText: cityErrorText,
                ),
                EditableField(
                  width: fieldWidth,
                  label: l10n.district,
                  controller: districtController,
                  requiredField: true,
                  helpMessage: l10n.districtHelp,
                  errorText: districtErrorText,
                ),
                EditableField(
                  width: fieldWidth,
                  label: l10n.municipality,
                  controller: municipalityController,
                  requiredField: true,
                  helpMessage: l10n.municipalityHelp,
                  errorText: municipalityErrorText,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: EditableField(
                width: constraints.maxWidth,
                label: l10n.fullAddress,
                controller: addressController,
                requiredField: true,
                helpMessage: l10n.fullAddressHelp,
                errorText: addressErrorText,
              ),
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
                  label: Text(isLoading ? l10n.savingAddress : l10n.saveAddress),
                  style: FilledButton.styleFrom(
                    backgroundColor: canSave ? const Color(0xFF0EA5E9) : null,
                    foregroundColor: Colors.white,
                    elevation: canSave ? 6 : 0,
                    shadowColor: const Color(0xFF0EA5E9).withValues(alpha: 0.45),
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
