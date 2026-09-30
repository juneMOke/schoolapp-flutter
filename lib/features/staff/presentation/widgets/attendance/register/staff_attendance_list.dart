import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_attendance_settings.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_day_register.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/attendance/register/staff_attendance_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le registre en liste : une ligne par agent, colonnes fixes, et la colonne
/// des heures seulement quand la liste filtrée compte un vacataire à l'heure.
/// Sous 900 dp, la liste défile horizontalement.
class StaffAttendanceList extends StatelessWidget {
  final StaffDayRegister register;
  final StaffAttendanceSettings settings;

  const StaffAttendanceList({
    super.key,
    required this.register,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width =
          constraints.maxWidth < AppDimensions.staffAttendanceListMinWidth
          ? AppDimensions.staffAttendanceListMinWidth
          : constraints.maxWidth;
      final showHours = register.showsHours;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              _Header(showHours: showHours),
              for (final row in register.rows) ...[
                const SizedBox(height: AppSpacing.sm),
                StaffAttendanceRow(
                  key: ValueKey(row.member.id),
                  row: row,
                  settings: settings,
                  frozen: register.frozen,
                  showHours: showHours,
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _Header extends StatelessWidget {
  final bool showHours;

  const _Header({required this.showHours});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Widget cell(String text) => Text(
      text.toUpperCase(),
      overflow: TextOverflow.ellipsis,
      style: AppTypography.labelSmall.copyWith(color: AppColors.textMutedAa),
    );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brSm,
      ),
      child: StaffAttendanceRowLayout(
        agent: cell(l10n.staffAttendanceColAgent),
        status: cell(l10n.staffAttendanceColStatus),
        times: cell(l10n.staffAttendanceColTimes),
        hours: showHours ? cell(l10n.staffAttendanceColHours) : null,
        late: cell(l10n.staffAttendanceColLate),
        action: const SizedBox.shrink(),
      ),
    );
  }
}
