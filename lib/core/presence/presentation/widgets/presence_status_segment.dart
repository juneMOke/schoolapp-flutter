import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le choix direct du statut dans la liste : Présent · Retard · Absent. Pas
/// de cycle ; retoucher le statut actif l'efface.
class PresenceStatusSegment extends StatelessWidget {
  final PresenceStatus status;
  final ValueChanged<PresenceStatus> onChoose;

  const PresenceStatusSegment({
    super.key,
    required this.status,
    required this.onChoose,
  });

  static const List<PresenceStatus> choices = [
    PresenceStatus.present,
    PresenceStatus.late,
    PresenceStatus.absent,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        for (final choice in choices)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: _Choice(
                label: PresenceLabels.status(l10n, choice),
                tone: PresenceTone.of(choice),
                selected: choice == status,
                hint: choice == status ? l10n.presenceMarkClearHint : null,
                onTap: () => onChoose(choice),
              ),
            ),
          ),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  final String label;
  final PresenceTone tone;
  final bool selected;
  final String? hint;
  final VoidCallback onTap;

  const _Choice({
    required this.label,
    required this.tone,
    required this.selected,
    required this.onTap,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final ink = selected ? AppColors.textOnDark : tone.ink;
    final button = Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? tone.color : AppColors.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brSm,
          side: BorderSide(color: selected ? tone.color : tone.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brSm,
          child: SizedBox(
            height: AppDimensions.presenceMarkSegmentHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(tone.icon, size: AppSpacing.lg, color: ink),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.labelMedium.copyWith(color: ink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final hint = this.hint;
    return hint == null ? button : Tooltip(message: hint, child: button);
  }
}
