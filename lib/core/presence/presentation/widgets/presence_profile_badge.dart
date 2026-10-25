import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_labels.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_profile_tone.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le profil d'une personne : glyphe et nom sur le voile de sa teinte — la
/// couleur ne le dit jamais seule. Sa règle en infobulle.
class PresenceProfileBadge extends StatelessWidget {
  final PresenceProfile profile;

  /// La version large de l'en-tête de fiche.
  final bool large;

  const PresenceProfileBadge({
    super.key,
    required this.profile,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = PresenceProfileTone.of(profile);
    return Tooltip(
      message: PresenceLabels.profileRule(l10n, profile),
      triggerMode: TooltipTriggerMode.longPress,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: large ? AppSpacing.md : AppSpacing.sm,
          vertical: large ? AppSpacing.xs : AppSpacing.xs / 2,
        ),
        decoration: BoxDecoration(
          color: tone.soft,
          borderRadius: AppRadius.brPill,
          border: Border.all(color: tone.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tone.icon,
              size: large
                  ? AppDimensions.presenceProfileBadgeIconLarge
                  : AppDimensions.presenceProfileBadgeIcon,
              color: tone.ink,
            ),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                PresenceLabels.profile(l10n, profile),
                style:
                    (large
                            ? AppTypography.titleSmall
                            : AppTypography.labelMedium)
                        .copyWith(color: tone.ink, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
