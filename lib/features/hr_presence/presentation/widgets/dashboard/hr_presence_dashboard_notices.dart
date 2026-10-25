import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « 6 jours-agent non pointés » : ils ne comptent ni comme présence ni comme
/// absence — et de quoi compléter le pointage. Ocre de l'attente, comme les
/// autres vigilances des tableaux de bord.
class HrPresenceUnscoredNotice extends StatelessWidget {
  final int unscored;

  /// `null` : le compte ne pointe pas, l'action n'est pas offerte.
  final VoidCallback? onComplete;

  const HrPresenceUnscoredNotice({
    super.key,
    required this.unscored,
    this.onComplete,
  }) : assert(unscored > 0, 'Rien à pointer : ne pas poser l\'alerte.');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final action = onComplete;
    return _Insight(
      tone: DashboardSense.attente,
      icon: Icons.pending_actions_outlined,
      title: l10n.hrPresenceUnscoredTitle(unscored),
      body: l10n.hrPresenceUnscoredBody,
      action: action == null
          ? null
          : EteeloButton.secondary(
              label: l10n.hrPresenceUnscoredAction,
              icon: Icons.edit_calendar_outlined,
              onPressed: action,
              fullWidth: false,
            ),
    );
  }
}

/// « 4 pointages encore sur la tablette » : les chiffres sont ceux du
/// serveur, qui ne les a pas encore reçus (D1). Aucune action : l'envoi est
/// automatique.
class HrPresenceUnsyncedNotice extends StatelessWidget {
  final int unsynced;

  const HrPresenceUnsyncedNotice({super.key, required this.unsynced})
    : assert(unsynced > 0, 'Rien en attente : ne pas poser l\'alerte.');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Insight(
      tone: DashboardSense.attendu,
      icon: Icons.cloud_off_outlined,
      title: l10n.hrPresenceUnsyncedTitle(unsynced),
      body: l10n.hrPresenceUnsyncedBody,
    );
  }
}

class _Insight extends StatelessWidget {
  final Color tone;
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  const _Insight({
    required this.tone,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    return Semantics(
      container: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: DashboardTones.teinte(tone, DashboardTones.zebrurePercent),
          borderRadius: AppRadius.brLg,
          border: Border.all(
            color: DashboardTones.teinte(
              tone,
              DashboardTones.zebrurePercent * 3,
            ),
          ),
        ),
        child: Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.md,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: AppDimensions.hrInsightIconSize,
                  color: DashboardTones.encreLisible(tone),
                ),
                const SizedBox(width: AppSpacing.md),
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppDimensions.hrPresenceInsightTextMaxWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTypography.titleSmall.copyWith(
                            color: DashboardTones.encreLisible(tone),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          body,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            ?action,
          ],
        ),
      ),
    );
  }
}
