import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/sujet_limits.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_duree.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Choix de la durée d'une évaluation (spec §4 bis) : pilules des durées
/// courantes, « Autre » (champ en minutes) et « Non définie » (`null`).
///
/// Partagé par la modale de création et l'éditeur du sujet.
class SujetDureePicker extends StatefulWidget {
  final int? value;
  final ValueChanged<int?> onChanged;

  const SujetDureePicker({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<SujetDureePicker> createState() => _SujetDureePickerState();
}

class _SujetDureePickerState extends State<SujetDureePicker> {
  late bool _other = _isOther(widget.value);
  late final TextEditingController _minutes = TextEditingController(
    text: _isOther(widget.value) ? '${widget.value}' : '',
  );

  /// Dernière valeur émise par ce widget : son retour par le parent n'est pas
  /// une valeur « imposée », il ne doit pas refermer « Autre » (taper « 60 »
  /// en route vers « 600 » passe par un préréglage).
  int? _emitted;

  static bool _isOther(int? value) =>
      value != null && !kDureePresets.contains(value);

  @override
  void didUpdateWidget(SujetDureePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final value = widget.value;
    if (value == oldWidget.value || value == _emitted) return;
    // Une valeur imposée de l'extérieur (défaut d'un type) : « Autre » suit.
    _other = _isOther(value);
    if (_other) _minutes.text = '$value';
  }

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  void _emit(int? minutes) {
    _emitted = minutes;
    widget.onChanged(minutes);
  }

  void _pick(int? minutes) {
    setState(() => _other = false);
    _emit(minutes);
  }

  /// Ouvre le champ minutes, prérempli avec la durée courante : la valeur ne
  /// change pas tant que rien n'est tapé.
  void _pickOther() => setState(() {
    _other = true;
    final value = widget.value;
    _minutes.text = value == null ? '' : '$value';
  });

  void _onMinutesChanged(String text) {
    final minutes = int.tryParse(text);
    _emit(
      minutes == null || minutes <= 0
          ? null
          : minutes.clamp(1, SujetLimits.dureeMinutesMax),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final value = widget.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final preset in kDureePresets)
              _chip(
                formatDuree(l10n, preset),
                selected: !_other && value == preset,
                onTap: () => _pick(preset),
              ),
            _chip(l10n.dureeOther, selected: _other, onTap: _pickOther),
            _chip(
              l10n.dureeUndefined,
              selected: !_other && value == null,
              onTap: () => _pick(null),
            ),
          ],
        ),
        if (_other) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              SizedBox(
                width: AppDimensions.sujetDureeOtherWidth,
                child: EteeloTextInput(
                  label: l10n.dureeOtherMinutes,
                  hideLabel: true,
                  placeholder: l10n.dureeOtherMinutes,
                  controller: _minutes,
                  keyboardType: EteeloTextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  onChanged: _onMinutesChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              if (value != null && value > 0)
                Text(
                  l10n.dureeEquivalent(formatDuree(l10n, value)),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _chip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) => EteeloFilterChip(
    label: label,
    selected: selected,
    color: AppColors.bleuArdoise,
    soft: AppColors.bleuArdoiseSoft,
    ink: AppColors.bleuArdoise,
    onTap: onTap,
  );
}
