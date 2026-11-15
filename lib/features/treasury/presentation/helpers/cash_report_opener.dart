import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_reports_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/cash_report_viewer.dart';

/// Ouvre un rapport de caisse dans sa visionneuse (A6), sur le format
/// demandé ; la bascule PDF | Excel y passe à l'autre. Utilisé par les
/// boutons de format (A5, B6) et par le clic sur un point de courbe (A4, R7).
Future<void> openCashReport(
  BuildContext context, {
  required String id,
  required String title,
  required CashReportFormat format,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  return showEteeloAdaptiveDialog<void>(
    context: context,
    builder: (_) => CashReportViewer(
      reportId: id,
      title: title,
      initialFormat: format,
      repository: GetIt.instance<TreasuryReportsRepository>(),
    ),
  );
}
