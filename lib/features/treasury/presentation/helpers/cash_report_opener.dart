import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_reports_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_failure_text.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre un rapport de caisse : le PDF dans la visionneuse partagée
/// (imprimer, partager le fichier : D29, pas de lien public), la feuille
/// Excel s'enregistre. Le fichier est généré à chaque appel ; un rapport
/// provisoire porte déjà son filigrane. Utilisé par les boutons de format
/// (A5, B6) et par le clic sur un point de courbe (A4, R7).
Future<void> openCashReport(
  BuildContext context, {
  required String id,
  required String title,
  required CashReportFormat format,
}) async {
  final result = await GetIt.instance<TreasuryReportsRepository>().file(
    id,
    format,
  );
  if (!context.mounted) return;
  await result.fold(
    (failure) async => _refused(context, failure),
    (file) => _deliver(context, file, id, title),
  );
}

void _refused(BuildContext context, Failure failure) {
  final l10n = AppLocalizations.of(context)!;
  AppSnackBar.showError(
    context,
    failure is TooManyRequestsFailure
        ? l10n.treasuryReportBusy
        : l10n.treasurySaveFailed(l10n.treasuryFailureReason(failure)),
  );
}

Future<void> _deliver(
  BuildContext context,
  CashReportFile file,
  String id,
  String title,
) async {
  final l10n = AppLocalizations.of(context)!;
  switch (file.format) {
    case CashReportFormat.pdf:
      await showEteeloDocumentViewer(
        context,
        title: title,
        document: PrintableDocument(
          bytes: file.bytes,
          fileName: file.fileName,
          reference: file.status == CashReportStatus.provisional
              ? l10n.treasuryReportProvisionalRef(id)
              : id,
        ),
      );
    case CashReportFormat.xlsx:
      final String? path;
      try {
        path = await FilePicker.saveFile(
          fileName: file.fileName,
          bytes: file.bytes,
        );
      } catch (_) {
        // Portail de fichiers absent, sélecteur déjà ouvert : on le dit.
        if (context.mounted) {
          AppSnackBar.showError(
            context,
            l10n.treasurySaveFailed(file.fileName),
          );
        }
        return;
      }
      // Le web télécharge sans rendre de chemin.
      if ((path != null || kIsWeb) && context.mounted) {
        AppSnackBar.showSuccess(
          context,
          l10n.treasuryReportSaved(file.fileName),
        );
      }
  }
}
