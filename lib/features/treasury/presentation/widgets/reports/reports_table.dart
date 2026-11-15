import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/tables/eteelo_column_table.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/cash_report_opener.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_tones.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/report_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le tableau des rapports (A5) : bandeau terre cuite, lignes zébrées, une
/// carte par rapport sous 760.
class ReportsTable extends StatelessWidget {
  final List<CashReport> reports;
  final DateTime today;

  const ReportsTable({super.key, required this.reports, required this.today});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return EteeloColumnTable(
      raised: true,
      tone: TreasuryTones.table,
      cardsBelow: AppDimensions.treasuryReportCardsBelow,
      minWidth: ReportColumns.minWidth,
      widths: ReportColumns.widths,
      headers: ReportColumns.headers(l10n),
      endAligned: const {3},
      rowCount: reports.length,
      row: (context, index) {
        final report = reports[index];
        return reportRow(
          context,
          report: report,
          isToday: report.kind == CashReportKind.daily && report.from == today,
          onOpen: () => openCashReport(
            context,
            id: report.id,
            title: report.title,
            format: CashReportFormat.pdf,
          ),
        );
      },
    );
  }
}
