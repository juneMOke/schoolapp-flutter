import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/cards/eteelo_stats_card.dart';
import 'package:school_app_flutter/core/components/search/eteelo_search_toolbar.dart';
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/listing_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/features/hr_presence/domain/entities/hr_attendance_dashboard.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/dashboard/hr_attendance_report_button.dart';
import 'package:school_app_flutter/features/hr_presence/presentation/widgets/dashboard/hr_presence_staff_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Assiduité par agent » : toujours du moins au plus assidu — l'ordre du
/// serveur, jamais retrié — et pas de sélecteur de tri ; à la place, le PDF
/// de ce seul tableau, lignes filtrées, même ordre.
///
/// Le tableau des tableaux de bord : carte de section teintée, une carte par
/// agent sur téléphone, défilement horizontal sous sa largeur plancher.
class HrPresenceStaffCard extends StatelessWidget {
  /// Un effectif : le bleu ardoise des listes de personnes.
  static const Color tone = DashboardSense.attendu;

  final HrAttendanceDashboard dashboard;
  final DashboardWindow window;

  /// « Ce mois · octobre 2026 ».
  final String periodLabel;
  final List<HrAttendanceStaffRow> rows;
  final String text;
  final ValueChanged<String> onTextChanged;
  final VoidCallback onClearText;

  /// `null` : les lignes ne s'ouvrent pas.
  final ValueChanged<HrAttendanceStaffRow>? onOpen;

  const HrPresenceStaffCard({
    super.key,
    required this.dashboard,
    required this.window,
    required this.periodLabel,
    required this.rows,
    required this.text,
    required this.onTextChanged,
    required this.onClearText,
    this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final open = onOpen;
    return EteeloStatsCard(
      title: l10n.hrPresenceStaffTitle,
      subtitle: open == null
          ? l10n.hrPresenceStaffSubtitle(periodLabel)
          : l10n.hrPresenceStaffSubtitleTap(periodLabel),
      icon: Icons.groups_outlined,
      tone: tone,
      toneStrength: DashboardTones.forceDe(tone),
      actions: [
        HrAttendanceReportButton(
          window: rows.isEmpty ? null : window,
          search: text,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EteeloSearchToolbar(
            text: text,
            label: l10n.hrPresenceStaffSearchLabel,
            placeholder: l10n.hrPresenceStaffSearchPlaceholder,
            onTextChanged: onTextChanged,
          ),
          const SizedBox(height: AppSpacing.md),
          if (rows.isEmpty)
            EteeloEmptyResult(
              label: l10n.hrPresenceStaffEmptyTitle,
              description: l10n.hrPresenceStaffEmptyMessage(text.trim()),
              medallionIcon: Icons.search_rounded,
              fullWidthCard: true,
              primaryAction: EteeloButton.secondary(
                label: l10n.hrPresenceStaffShowAll,
                icon: Icons.close,
                onPressed: onClearText,
                fullWidth: false,
              ),
            )
          else
            DataTableView(
              rows: [
                for (final row in rows)
                  HrPresenceStaffRow.of(
                    row,
                    l10n,
                    onOpen: open == null ? null : () => open(row),
                  ),
              ],
              config: DataTableViewConfig(
                tone: ListingTones.tableTone(tone),
                semanticsLabel: l10n.hrPresenceStaffTitle,
                density: DataTableDensity.compact,
                phoneLayout: DataTablePhoneLayout.cards,
                columns: [
                  DataTableColumnDef(label: l10n.hrPresenceColAgent, flex: 22),
                  DataTableColumnDef(label: l10n.hrPresenceColJob, flex: 14),
                  DataTableColumnDef(label: l10n.hrPresenceColRate, flex: 12),
                  DataTableColumnDef(label: l10n.hrPresenceColLate, flex: 11),
                  DataTableColumnDef(
                    label: l10n.hrPresenceColJustified,
                    flex: 8,
                  ),
                  DataTableColumnDef(
                    label: l10n.hrPresenceColUnjustified,
                    flex: 8,
                  ),
                ],
                footer: DataTableFooterConfig(
                  label: l10n.hrAgentsCount(rows.length),
                  total: rows.length,
                  unit: l10n.hrRosterUnit,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
