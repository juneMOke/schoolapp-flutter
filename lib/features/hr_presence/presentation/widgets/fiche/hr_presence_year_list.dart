import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/components/tables/data_table_trailing_registry.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_data_table_theme.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/presence/domain/presence_profile.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_profile_badge.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_share_bar.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_agent_year.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_kpis.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La vue annuelle : la table teintée des autres écrans
/// ([EteeloColumnTable], [ListingTones.table]), une ligne par mois de l'année
/// scolaire — barre tricolore, trois taux en colonnes, jours pointés, profil
/// du mois — et l'année en pied. Les colonnes alignées comparent les mois de
/// haut en bas. Vacances et mois à venir se disent, et ne s'ouvrent pas ; un
/// mois de classe ouvre sa vue mensuelle. Sous sa largeur plancher, elle
/// défile de côté et le mois reste à l'écran.
class HrPresenceYearList extends StatelessWidget {
  final List<HrAttendanceMonthSummary> months;

  /// Le total de l'année et son profil, en pied ; `null` : pas de pied.
  final HrAttendanceKpis? total;
  final PresenceProfile? totalProfile;
  final ValueChanged<String> onOpenMonth;

  const HrPresenceYearList({
    super.key,
    required this.months,
    required this.onOpenMonth,
    this.total,
    this.totalProfile,
  });

  static const List<double?> _widths = [
    AppDimensions.hrPresenceYearMonthWidth,
    AppDimensions.hrPresenceYearColShare,
    AppDimensions.hrPresenceYearColRate,
    AppDimensions.hrPresenceYearColRate,
    AppDimensions.hrPresenceYearColRate,
    AppDimensions.hrPresenceYearColScored,
    null,
    EteeloDataTableTheme.trailingSlotWidth,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final total = this.total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.hrPresenceYearTitle,
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        EteeloColumnTable(
          tone: ListingTones.table,
          minWidth: AppDimensions.hrPresenceYearMinWidth,
          frozenFirstColumn: true,
          widths: _widths,
          endAligned: const {2, 3, 4, 5},
          headers: [
            l10n.hrPresenceYearColMonth,
            l10n.hrPresenceYearColShare,
            l10n.hrPresenceYearColPresence,
            l10n.presenceMarkKpiLates,
            l10n.presenceMarkKpiAbsences,
            l10n.hrPresenceYearColScored,
            l10n.hrPresenceYearColProfile,
            '',
          ],
          rowCount: months.length,
          row: (context, index) =>
              _MonthRow(month: months[index], onOpen: onOpenMonth),
          footer: total == null
              ? null
              : _TotalRow(
                  total: total,
                  classDays: months.fold(
                    0,
                    (sum, month) => sum + month.classDays,
                  ),
                  profile: totalProfile,
                ),
        ),
      ],
    );
  }
}

String _rate(AppLocalizations l10n, int? pct) =>
    pct == null ? l10n.hrPresenceNoValue : l10n.presenceRateValue(pct);

/// Un taux ou un compte, aligné à droite en chiffres tabulaires.
Widget _figure(String text, {bool strong = false, Color? color}) => Text(
  text,
  textAlign: TextAlign.end,
  style: EteeloColumnTableRow.figures(color: color, strong: strong),
);

/// La barre tricolore : à l'heure, en retard, absent, en % des jours pointés.
Widget _share({required int? presence, required int? late, int? absent}) =>
    Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: AppDimensions.presenceShareBarWidth,
        child: PresenceShareBar(
          onTimePct: presence == null
              ? 0
              : (presence - (late ?? 0)).clamp(0, 100),
          latePct: late ?? 0,
          absentPct: absent ?? 0,
        ),
      ),
    );

class _MonthRow extends StatelessWidget {
  final HrAttendanceMonthSummary month;
  final ValueChanged<String> onOpen;

  const _MonthRow({required this.month, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dates = MaterialLocalizations.of(context);
    final date = DateTime.tryParse('${month.month}-01');
    final name = date == null ? month.month : dates.formatMonthYear(date);
    final openable = month.isOpenable;
    final muted = AppTypography.bodySmall.copyWith(
      color: AppColors.textMutedAa,
    );
    final nameCell = Text(
      name,
      style: AppTypography.labelLarge.copyWith(
        color: openable ? AppColors.textPrimary : AppColors.textMutedAa,
      ),
    );
    final List<Widget> cells = switch (month.state) {
      HrAttendanceMonthState.classMonth => [
        nameCell,
        _share(
          presence: month.presenceRatePct,
          late: month.lateRatePct,
          absent: month.absenceRatePct,
        ),
        _figure(_rate(l10n, month.presenceRatePct)),
        _figure(_rate(l10n, month.lateRatePct)),
        _figure(_rate(l10n, month.absenceRatePct)),
        _figure(l10n.presenceMarkKpiRatio(month.scored, month.classDays)),
        Align(
          alignment: Alignment.centerLeft,
          child: PresenceProfileBadge(profile: month.profile),
        ),
        // L'œil des tables de l'app : toute la ligne ouvre aussi.
        DataTableTrailingRegistry.build(
          context,
          DataTableTrailingSpec(
            type: DataTableTrailingType.eye,
            tooltip: l10n.hrPresenceYearOpen,
            onTap: () => onOpen(month.month),
          ),
        ),
      ],
      // Vacances ou à venir : le mois se dit dans la colonne de la barre, le
      // reste se tait.
      HrAttendanceMonthState.holiday || HrAttendanceMonthState.future => [
        nameCell,
        Text(
          month.state == HrAttendanceMonthState.holiday
              ? l10n.hrPresenceMonthHoliday
              : l10n.hrPresenceMonthFuture,
          style: muted,
        ),
        for (var i = 0; i < 4; i++)
          _figure(l10n.hrPresenceNoValue, color: AppColors.textMutedAa),
        const SizedBox.shrink(),
        const SizedBox.shrink(),
      ],
    };
    final row = EteeloColumnTableRow(
      widths: HrPresenceYearList._widths,
      onTap: openable ? () => onOpen(month.month) : null,
      cells: cells,
    );
    if (!openable) return row;
    // Une seule phrase pour le lecteur d'écran : le mois et ses taux.
    return Semantics(
      button: true,
      label: l10n.hrPresenceYearRowA11y(
        name,
        _rate(l10n, month.presenceRatePct),
        _rate(l10n, month.lateRatePct),
        _rate(l10n, month.absenceRatePct),
      ),
      excludeSemantics: true,
      onTap: () => onOpen(month.month),
      child: row,
    );
  }
}

/// Le pied : l'année entière, ses taux et son profil.
class _TotalRow extends StatelessWidget {
  final HrAttendanceKpis total;
  final int classDays;
  final PresenceProfile? profile;

  const _TotalRow({
    required this.total,
    required this.classDays,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final profile = this.profile;
    return EteeloColumnTableRow(
      widths: HrPresenceYearList._widths,
      background: AppColors.surfaceAlt,
      cells: [
        Text(l10n.hrPresenceYearTotal, style: AppTypography.labelLarge),
        _share(
          presence: total.presenceRatePct,
          late: total.lateRatePct,
          absent: total.absenceRatePct,
        ),
        _figure(_rate(l10n, total.presenceRatePct), strong: true),
        _figure(_rate(l10n, total.lateRatePct), strong: true),
        _figure(_rate(l10n, total.absenceRatePct), strong: true),
        _figure(
          l10n.presenceMarkKpiRatio(total.scored, classDays),
          strong: true,
        ),
        if (profile == null)
          const SizedBox.shrink()
        else
          Align(
            alignment: Alignment.centerLeft,
            child: PresenceProfileBadge(profile: profile),
          ),
        const SizedBox.shrink(),
      ],
    );
  }
}
