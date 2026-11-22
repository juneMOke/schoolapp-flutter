import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/documents/data/utils/content_disposition_parser.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/count_pending_payments_use_case.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/domain/repositories/recovery_dashboard_repository.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/reports/cash_report_viewer.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La visionneuse d'un export du tableau de bord (O3) — **extension** de
/// celle de Trésorerie ▸ Rapports : bascule PDF | Excel, partage,
/// téléchargement, impression.
///
/// Le document est composé par le serveur sur la question de l'écran ; chaque
/// format n'est demandé qu'**une fois** par ouverture : un PDF `ER` consomme un
/// numéro de pièce, et basculer ne doit pas en brûler un autre (I19).
class RecoveryExportViewer extends StatelessWidget {
  final RecoveryStudentsQuery query;
  final String title;
  final RecoveryExportFormat initialFormat;
  final RecoveryDashboardRepository repository;
  final CountPendingPaymentsUseCase countPending;

  /// Couture de test : la page PDF ne se rasterise pas en test widget.
  final Widget Function(CashReportFile file)? pdfPreviewBuilder;

  const RecoveryExportViewer({
    super.key,
    required this.query,
    required this.title,
    required this.initialFormat,
    required this.repository,
    required this.countPending,
    this.pdfPreviewBuilder,
  });

  static CashReportFormat _toCash(RecoveryExportFormat f) =>
      f == RecoveryExportFormat.pdf
      ? CashReportFormat.pdf
      : CashReportFormat.xlsx;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CashReportViewer(
      reportId: l10n.recoveryExportReference,
      title: title,
      initialFormat: _toCash(initialFormat),
      pdfPreviewBuilder: pdfPreviewBuilder,
      subtitleBuilder: (file) {
        final number = file?.format == CashReportFormat.pdf
            ? ContentDispositionParser.documentNumber(
                file?.fileName.replaceFirst('recouvrement-', ''),
              )
            : null;
        return number == null
            ? l10n.recoveryExportReference
            : l10n.recoveryExportReferenceNumber(number);
      },
      loader: (format) async {
        final pending = (await countPending()).fold((_) => 0, (n) => n);
        final result = await repository.export(
          query,
          format == CashReportFormat.pdf
              ? RecoveryExportFormat.pdf
              : RecoveryExportFormat.xlsx,
          pendingWrites: pending,
        );
        return result.map(
          (file) => CashReportFile(
            bytes: file.bytes,
            fileName: file.fileName,
            format: format,
          ),
        );
      },
    );
  }
}
