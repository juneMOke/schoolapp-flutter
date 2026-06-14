import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_absence_entry.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_status.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/presence_summary_view_data.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Carte depliable listant les jours non presents (absences justifiees /
/// injustifiees), du plus recent au plus ancien. Fermee par defaut.
class PresenceAbsenceList extends StatefulWidget {
  final PresenceSummaryViewData data;

  const PresenceAbsenceList({super.key, required this.data});

  @override
  State<PresenceAbsenceList> createState() => _PresenceAbsenceListState();
}

class _PresenceAbsenceListState extends State<PresenceAbsenceList> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final absences = widget.data.sortedAbsences;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(l10n, absences.length),
          AnimatedSize(
            duration: AppMotion.standard,
            curve: AppMotion.outCurve,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [for (final entry in absences) _row(l10n, entry)],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _header(AppLocalizations l10n, int count) {
    return Semantics(
      button: true,
      expanded: _expanded,
      label: l10n.presenceAbsenceListTitle,
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingM,
          ),
          child: Row(
            children: [
              Container(
                width: AppDimensions.presenceMedallionSize,
                height: AppDimensions.presenceMedallionSize,
                decoration: BoxDecoration(
                  color: AppColors.bleuArdoise.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.presenceMedallionRadius,
                  ),
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: AppDimensions.detailMiniIconSize,
                  color: AppColors.bleuArdoise,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  l10n.presenceAbsenceListTitle,
                  style: AppTextStyles.sectionTitle.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              _CountBadge(count: count),
              const SizedBox(width: AppDimensions.spacingS),
              AnimatedRotation(
                turns: _expanded ? 0.5 : 0,
                duration: AppMotion.standard,
                curve: AppMotion.outCurve,
                child: const Icon(
                  Icons.expand_more_rounded,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(AppLocalizations l10n, StudentAbsenceEntry entry) {
    final status = AttendanceDayStatusX.forAbsenceReason(entry.reason);
    final note = (entry.reasonNote ?? '').trim();

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.spacingM,
          vertical: AppDimensions.spacingS,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: AppDimensions.presenceRowAccentBarWidth,
              height: AppDimensions.presenceRowAccentBarHeight,
              decoration: BoxDecoration(
                color: status.color,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.presenceAbsenceDate(entry.date),
                    style: AppTextStyles.bodyStrong.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (note.isNotEmpty)
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppDimensions.spacingS),
            _StatusPill(status: status),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;

  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: AppTextStyles.badge.copyWith(
          color: AppColors.textSecondary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final AttendanceDayStatus status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 13, color: status.color),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            status.label(l10n),
            style: AppTextStyles.badge.copyWith(color: status.color),
          ),
        ],
      ),
    );
  }
}
