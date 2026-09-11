import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_levels_pdf.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_export_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La sortie **composée sur l'appareil** — le classement par niveau — et ce
/// qu'elle fait quand elle échoue.
///
/// Des comptes, pas des noms : rien qui justifie un aller-retour serveur. La
/// liste nominative, elle, s'imprime depuis le serveur
/// (`EnrollmentEntriesReportButton`) : un registre de **toute** la fenêtre,
/// pas la seule page à l'écran.
///
/// ## Un échec se dit, il ne se tait pas
///
/// Le geste traverse une surface système — le spouleur d'impression — qui
/// peut être absente ou refuser. Sans reprise, l'appui ne produirait alors
/// *rien du tout* : pas de document, pas de message, aucun moyen de distinguer
/// un export raté d'un clic mal enregistré. L'échec se termine donc par un
/// toast.
abstract final class EnrollmentExportActions {
  /// Le bouton PDF du classement par niveau.
  static Widget levelsPdf({
    required BuildContext context,
    required List<LevelStat> levels,
    required String schoolYear,
    required DateTime generatedAt,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return EnrollmentExportButton(
      // ⚠️ Écart assumé à la spec d'origine, demandé par le porteur produit :
      // elle mettait `file-text` sur le PDF. Le glyphe de téléchargement le
      // remplace, et le bouton écrit son nom.
      icon: Icons.download_outlined,
      label: l10n.enrollmentDashboardExportPdf,
      tooltip: l10n.enrollmentDashboardExportPdfTooltip,
      onPressed: () => _printLevels(
        context,
        levels: levels,
        schoolYear: schoolYear,
        generatedAt: generatedAt,
      ),
    );
  }

  static Future<void> _printLevels(
    BuildContext context, {
    required List<LevelStat> levels,
    required String schoolYear,
    required DateTime generatedAt,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final generatedOn = MaterialLocalizations.of(
      context,
    ).formatFullDate(generatedAt);

    try {
      final bytes = await EnrollmentLevelsPdf.render(
        levels: levels,
        schoolYear: schoolYear,
        generatedOn: generatedOn,
        labels: PdfLevelsLabels(
          overtitle: l10n.enrollmentDashboardPdfOvertitle,
          title: l10n.enrollmentDashboardPdfTitle,
          columnLevel: l10n.enrollmentDashboardPdfColumnLevel,
          columnCycle: l10n.enrollmentDashboardPdfColumnCycle,
          columnCount: l10n.enrollmentDashboardPdfColumnCount,
          subtitle: l10n.enrollmentDashboardPdfSubtitle,
          footer: l10n.enrollmentDashboardPdfFooter,
        ),
      );

      // Le document est composé AVANT d'ouvrir le spouleur : une composition
      // impossible se dit tout de suite, plutôt qu'après avoir ouvert une
      // boîte de dialogue d'impression qui se refermerait seule.
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: l10n.enrollmentDashboardPdfTitle,
      );
    } catch (_) {
      // Canal de plateforme absent, service d'impression indisponible : les
      // données sont intactes, seul le geste a échoué.
      if (!context.mounted) return;
      AppSnackBar.showError(context, l10n.enrollmentDashboardPdfFailed);
    }
  }
}
