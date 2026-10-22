import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_pickers.dart';
import 'package:school_app_flutter/core/components/labels/form_section_label.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/remise_devoir.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bloc « Remise » d'un devoir : en classe ou en ligne, une heure limite
/// facultative, et — en ligne seulement — l'acceptation des dépôts en retard.
/// Le jour d'échéance reste la date du devoir.
class RemiseDevoirFields extends StatefulWidget {
  final RemiseDevoir remise;
  final ValueChanged<RemiseDevoir> onChanged;

  const RemiseDevoirFields({
    super.key,
    required this.remise,
    required this.onChanged,
  });

  @override
  State<RemiseDevoirFields> createState() => _RemiseDevoirFieldsState();
}

class _RemiseDevoirFieldsState extends State<RemiseDevoirFields> {
  final TextEditingController _heure = TextEditingController();

  @override
  void dispose() {
    _heure.dispose();
    super.dispose();
  }

  void _emit(RemiseDevoir remise) => widget.onChanged(remise.normalized());

  Future<void> _pickHeure() async {
    final current = widget.remise.heureLimite?.split(':');
    final picked = await showEteeloTimePicker(
      context: context,
      initialTime: current == null
          ? const TimeOfDay(hour: 17, minute: 0)
          : TimeOfDay(
              hour: int.parse(current[0]),
              minute: int.parse(current[1]),
            ),
    );
    if (!mounted || picked == null) return;
    String two(int value) => value.toString().padLeft(2, '0');
    _emit(
      widget.remise.copyWith(
        heureLimite: () => '${two(picked.hour)}:${two(picked.minute)}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remise = widget.remise;
    final heure = remise.heureLimite;
    _heure.text = heure ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FormSectionLabel(label: l10n.remiseSectionLabel),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final mode in ModeRemise.values)
              EteeloFilterChip(
                label: mode == ModeRemise.enClasse
                    ? l10n.remiseModeEnClasse
                    : l10n.remiseModeEnLigne,
                icon: mode == ModeRemise.enClasse
                    ? Icons.school_outlined
                    : Icons.cloud_upload_outlined,
                selected: remise.mode == mode,
                color: AppColors.bleuArdoise,
                soft: AppColors.bleuArdoiseSoft,
                ink: AppColors.bleuArdoise,
                onTap: () => _emit(remise.copyWith(mode: mode)),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: EteeloTextInput(
                controller: _heure,
                label: l10n.remiseHeureLimiteLabel,
                placeholder: l10n.remiseHeureLimiteHint,
                readOnly: true,
                capitalization: EteeloTextCapitalization.none,
                prefix: const Icon(Icons.schedule),
                onTap: _pickHeure,
              ),
            ),
            if (heure != null)
              IconButton(
                tooltip: l10n.remiseHeureLimiteClear,
                icon: const Icon(Icons.close),
                onPressed: () =>
                    _emit(remise.copyWith(heureLimite: () => null)),
              ),
          ],
        ),
        if (remise.enLigne)
          CheckboxListTile(
            value: remise.depotTardifPermis,
            onChanged: (value) =>
                _emit(remise.copyWith(depotTardifPermis: value ?? false)),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: Text(l10n.remiseDepotTardifLabel),
          ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          remise.enLigne ? l10n.remiseEnLigneHelp : l10n.remiseEnClasseHelp,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
