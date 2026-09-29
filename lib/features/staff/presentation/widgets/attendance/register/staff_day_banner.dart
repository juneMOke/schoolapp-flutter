import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_day_progress_ring.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau du registre : navigation de jour, réglages, progression et
/// actions (restants présents, valider). Les actions disparaissent une fois
/// le rapport validé — le bandeau vert prend le relais.
class StaffDayBanner extends StatelessWidget {
  final StaffDayRegister register;
  final StaffAttendanceSettings settings;
  final bool isToday;
  final VoidCallback onPrevious;

  /// `null` : aujourd'hui, pas de jour suivant.
  final VoidCallback? onNext;
  final VoidCallback onToday;
  final VoidCallback onSettings;
  final VoidCallback onMarkRemaining;
  final VoidCallback onValidate;

  const StaffDayBanner({
    super.key,
    required this.register,
    required this.settings,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
    required this.onSettings,
    required this.onMarkRemaining,
    required this.onValidate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const onBanner = AppColors.staffAttendanceOnBanner;
    final unmarked = register.count(StaffAttendanceStatus.none);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        borderRadius: AppRadius.brCard,
        gradient: LinearGradient(
          colors: [
            AppColors.staffAttendanceBannerStart,
            AppColors.staffAttendanceBannerMid,
            AppColors.staffAttendanceBannerEnd,
          ],
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _NavButton(
                icon: Icons.chevron_left,
                tooltip: l10n.staffAttendancePreviousDay,
                onPressed: onPrevious,
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (isToday
                            ? l10n.staffAttendanceEyebrowToday
                            : l10n.staffAttendanceEyebrowPast)
                        .toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.staffAttendanceOnBannerMuted,
                    ),
                  ),
                  Text(
                    StaffAttendanceLabels.longDay(
                      MaterialLocalizations.of(context),
                      register.day,
                    ),
                    style: AppTypography.titleLarge.copyWith(color: onBanner),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _SettingsPill(settings: settings, onTap: onSettings),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              _NavButton(
                icon: Icons.chevron_right,
                tooltip: l10n.staffAttendanceNextDay,
                onPressed: onNext,
              ),
              if (!isToday) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  onPressed: onToday,
                  style: TextButton.styleFrom(foregroundColor: onBanner),
                  child: Text(l10n.staffAttendanceGoToday),
                ),
              ],
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StaffDayProgressRing(
                marked: register.marked,
                total: register.all.length,
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.staffAttendanceProgress(
                      register.marked,
                      register.all.length,
                    ),
                    style: AppTypography.titleMedium.copyWith(color: onBanner),
                  ),
                  Text(
                    [
                      l10n.staffAttendanceBadgeToMark(unmarked),
                      if (register.pending > 0)
                        l10n.staffAttendanceOnTablet(register.pending),
                    ].join(' · '),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.staffAttendanceOnBannerMuted,
                    ),
                  ),
                ],
              ),
              if (!register.frozen)
                PermissionGate.access(
                  kStaffAttendanceWriteAccess,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: AppSpacing.md),
                      _NavButton(
                        icon: Icons.checklist,
                        tooltip: l10n.staffAttendanceMarkRemaining,
                        onPressed: unmarked == 0 ? null : onMarkRemaining,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      EteeloButton.primary(
                        label: l10n.staffAttendanceValidateReport,
                        icon: Icons.task_alt,
                        onPressed: register.isEmpty ? null : onValidate,
                        fullWidth: false,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _NavButton({required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppDimensions.staffAttendanceTapTarget,
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: AppColors.staffAttendanceOnBanner,
      disabledColor: AppColors.staffAttendanceOnBannerFaint,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        side: const BorderSide(color: AppColors.staffAttendanceOnBannerMuted),
      ),
    ),
  );
}

class _SettingsPill extends StatelessWidget {
  final StaffAttendanceSettings settings;
  final VoidCallback onTap;

  const _SettingsPill({required this.settings, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: AppRadius.brPill,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.brPill,
        border: Border.all(color: AppColors.staffAttendanceOnBannerMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.tune,
            size: AppSpacing.lg,
            color: AppColors.staffAttendanceOnBanner,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            AppLocalizations.of(context)!.staffAttendanceSettingsPill(
              settings.start.wire,
              settings.toleranceMinutes,
            ),
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.staffAttendanceOnBanner,
            ),
          ),
        ],
      ),
    ),
  );
}
