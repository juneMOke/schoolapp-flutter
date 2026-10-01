import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/domain/presence_schedule.dart';
import 'package:school_app_flutter/core/presence/domain/presence_rules.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// L'encart qui dit, avant d'enregistrer, comment une arrivée sera classée.
class PresenceArrivalPreview extends StatelessWidget {
  final ArrivalClass result;
  final PresenceSchedule schedule;

  const PresenceArrivalPreview({
    super.key,
    required this.result,
    required this.schedule,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = PresenceTone.of(result.status);
    final late = result.status == PresenceStatus.late;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tone.soft,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: tone.border),
      ),
      child: Row(
        children: [
          Icon(tone.icon, color: tone.ink),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              late
                  ? l10n.presenceMarkPreviewLate(
                      result.lateMinutes,
                      schedule.start.wire,
                      schedule.toleranceMinutes,
                    )
                  : l10n.presenceMarkPreviewOnTime(schedule.lastOnTime.wire),
              style: AppTypography.bodyMedium.copyWith(color: tone.ink),
            ),
          ),
        ],
      ),
    );
  }
}
