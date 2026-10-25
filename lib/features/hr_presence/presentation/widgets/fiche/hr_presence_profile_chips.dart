import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_filter_chip.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_profile_tone.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une puce par profil présent dans la sélection, avec son compte : un appui
/// filtre, un second retire le filtre. La règle du profil en infobulle.
class HrPresenceProfileChips extends StatelessWidget {
  final Map<PresenceProfile, int> counts;
  final PresenceProfile? selected;
  final ValueChanged<PresenceProfile> onToggle;

  const HrPresenceProfileChips({
    super.key,
    required this.counts,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final MapEntry(key: profile, value: count) in counts.entries)
          Tooltip(
            message: PresenceLabels.profileRule(l10n, profile),
            child: EteeloFilterChip(
              label: PresenceLabels.profile(l10n, profile),
              count: count,
              selected: selected == profile,
              color: PresenceProfileTone.of(profile).color,
              soft: PresenceProfileTone.of(profile).soft,
              ink: PresenceProfileTone.of(profile).ink,
              icon: PresenceProfileTone.of(profile).icon,
              onTap: () => onToggle(profile),
            ),
          ),
      ],
    );
  }
}
