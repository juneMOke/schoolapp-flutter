import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_attendance_state.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_attendance_tone.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les trois onglets en cartes : titre jamais tronqué, sous-titre court et
/// badge d'état sur la même ligne.
class StaffAttendanceTabs extends StatelessWidget {
  final StaffAttendanceState state;
  final ValueChanged<StaffAttendanceTab> onSelect;

  const StaffAttendanceTabs({
    super.key,
    required this.state,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final register = state.register;
    final validated = state.snapshot.isDayValidated(state.day);
    final closed = state.snapshot.isMonthClosed(state.month);
    final unmarked = register.count(StaffAttendanceStatus.none);
    final tabs = [
      _TabData(
        StaffAttendanceTab.register,
        Icons.fact_check_outlined,
        l10n.staffAttendanceTabRegister,
        l10n.staffAttendanceTabRegisterSubtitle(
          register.marked,
          register.all.length,
        ),
        validated
            ? (
                l10n.staffAttendanceBadgeValidated,
                StaffAttendanceStatus.present,
              )
            : unmarked > 0
            ? (
                l10n.staffAttendanceBadgeToMark(unmarked),
                StaffAttendanceStatus.late,
              )
            : null,
      ),
      _TabData(
        StaffAttendanceTab.agentMonth,
        Icons.person_search_outlined,
        l10n.staffAttendanceTabAgent,
        l10n.staffAttendanceTabAgentSubtitle(
          StaffAttendanceLabels.month(
            MaterialLocalizations.of(context),
            state.month,
          ),
        ),
        null,
      ),
      _TabData(
        StaffAttendanceTab.recap,
        Icons.summarize_outlined,
        l10n.staffAttendanceTabRecap,
        l10n.staffAttendanceTabRecapSubtitle,
        closed
            ? (l10n.staffAttendanceBadgeClosed, StaffAttendanceStatus.present)
            : state.canCloseMonth &&
                  PermissionGate.allows(
                    context,
                    kStaffAttendanceManageAccess.requires,
                  )
            ? (l10n.staffAttendanceBadgeToClose, StaffAttendanceStatus.none)
            : null,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - AppSpacing.sm * (tabs.length - 1)) /
            tabs.length;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final tab in tabs)
              SizedBox(
                width: width,
                child: _TabCard(
                  data: tab,
                  active: tab.tab == state.tab,
                  onTap: () => onSelect(tab.tab),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TabData {
  final StaffAttendanceTab tab;
  final IconData icon;
  final String title;
  final String subtitle;
  final (String, StaffAttendanceStatus)? badge;

  const _TabData(this.tab, this.icon, this.title, this.subtitle, this.badge);
}

class _TabCard extends StatelessWidget {
  final _TabData data;
  final bool active;
  final VoidCallback onTap;

  const _TabCard({
    required this.data,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ink = active
        ? AppColors.staffAttendanceOnBanner
        : AppColors.textPrimary;
    final muted = active
        ? AppColors.staffAttendanceOnBannerMuted
        : AppColors.textSecondary;
    final badge = data.badge;
    return Semantics(
      button: true,
      selected: active,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brLg,
          child: Ink(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.brLg,
              color: active ? null : AppColors.surfaceRaised,
              gradient: active
                  ? const LinearGradient(
                      colors: [
                        AppColors.staffAttendanceBannerStart,
                        AppColors.staffAttendanceBannerMid,
                      ],
                    )
                  : null,
              border: Border(
                bottom: BorderSide(
                  color: active ? AppColors.terreCuite : AppColors.border,
                  width: AppSpacing.xs,
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: AppSpacing.lg + AppSpacing.xs,
                  backgroundColor: active
                      ? AppColors.terreCuite
                      : AppColors.surfaceAlt,
                  child: Icon(
                    data.icon,
                    color: active
                        ? AppColors.staffAttendanceOnBanner
                        : AppColors.bleuArdoise,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: AppTypography.titleSmall.copyWith(color: ink),
                      ),
                      Wrap(
                        spacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            data.subtitle,
                            style: AppTypography.bodySmall.copyWith(
                              color: muted,
                            ),
                          ),
                          if (badge != null) _Badge(badge.$1, badge.$2),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final StaffAttendanceStatus tone;

  const _Badge(this.label, this.tone);

  @override
  Widget build(BuildContext context) {
    final colors = StaffAttendanceTone.of(tone);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs / 2,
      ),
      decoration: BoxDecoration(
        color: colors.soft,
        borderRadius: AppRadius.brPill,
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: colors.ink),
      ),
    );
  }
}
