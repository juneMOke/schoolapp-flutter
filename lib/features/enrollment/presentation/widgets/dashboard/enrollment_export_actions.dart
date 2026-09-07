import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/dashboard/enrollment_export_button.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_day_entries_csv.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_day_entries_pdf.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_levels_pdf.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux sorties de l'écran, et **ce qu'elles font quand elles échouent**.
///
/// ## Un échec se dit, il ne se tait pas
///
/// Les deux gestes traversent une surface système — le spouleur d'impression,
/// le presse-papier — qui peut être absente ou refuser. Sans reprise, l'appui
/// sur le bouton ne produirait alors *rien du tout* : pas de document, pas de
/// message, aucun moyen de distinguer un export raté d'un clic mal enregistré.
/// Chaque sortie se termine donc par un toast, réussite comme échec.
///
/// ## Le CSV va au presse-papier
///
/// Décision assumée, et le nominatif en est la raison : `Printing.sharePdf` —
/// le seul chemin de partage de fichier du dépôt — écrit la pièce **en clair
/// dans le cache de l'application et ne l'efface jamais**. Pour une liste de
/// noms d'élèves, un presse-papier volatil vaut mieux qu'un fichier qui
/// séjourne. Conséquence acceptée : le nom de fichier de la spec n'existe que
/// dans le message de confirmation.
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
      // remplace — le CSV garde son tableur, et chaque bouton écrit son nom,
      // donc les deux restent distincts au premier coup d'œil.
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

  /// Le bouton PDF de la liste nominative du jour.
  ///
  /// ⚠️ Le document est **nominatif** : il quitte l'application avec des noms
  /// d'élèves. Il n'existe que là où la carte existe — une fenêtre d'un jour,
  /// derrière la permission serveur de la liste.
  static Widget dayEntriesPdf({
    required BuildContext context,
    required List<DayEnrollmentEntry> entries,
    required DateTime day,
    required String schoolYear,
    required DateTime generatedAt,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return EnrollmentExportButton(
      icon: Icons.download_outlined,
      label: l10n.enrollmentDashboardExportPdf,
      tooltip: l10n.enrollmentDashboardExportPdfTooltip,
      onPressed: () => _printDayEntries(
        context,
        entries: entries,
        day: day,
        schoolYear: schoolYear,
        generatedAt: generatedAt,
      ),
    );
  }

  /// Le bouton CSV de la liste du jour.
  static Widget dayEntriesCsv({
    required BuildContext context,
    required List<DayEnrollmentEntry> entries,
    required DateTime day,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return EnrollmentExportButton(
      icon: Icons.table_view_outlined,
      label: l10n.enrollmentDashboardExportCsv,
      tooltip: l10n.enrollmentDashboardExportCsvTooltip,
      onPressed: () => _copyDayEntries(context, entries: entries, day: day),
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

  static Future<void> _printDayEntries(
    BuildContext context, {
    required List<DayEnrollmentEntry> entries,
    required DateTime day,
    required String schoolYear,
    required DateTime generatedAt,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final materialL10n = MaterialLocalizations.of(context);
    final dayLabel = materialL10n.formatFullDate(day);
    final generatedOn = materialL10n.formatFullDate(generatedAt);

    try {
      final bytes = await EnrollmentDayEntriesPdf.render(
        entries: entries,
        schoolYear: schoolYear,
        day: dayLabel,
        generatedOn: generatedOn,
        labels: PdfDayEntriesLabels(
          overtitle: l10n.enrollmentDashboardPdfOvertitle,
          title: l10n.enrollmentDashboardDayListTitle,
          columnHour: l10n.enrollmentDashboardDayListColumnHour,
          columnStudent: l10n.enrollmentDashboardDayListColumnStudent,
          columnGender: l10n.enrollmentDashboardCsvColumnGender,
          columnLevel: l10n.enrollmentDashboardDayListColumnLevel,
          columnType: l10n.enrollmentDashboardDayListColumnType,
          columnRecordedBy: l10n.enrollmentDashboardDayListColumnRecordedBy,
          female: l10n.enrollmentDashboardGenderGirls,
          male: l10n.enrollmentDashboardGenderBoys,
          typeFirst: l10n.enrollmentDashboardTypeFirst,
          typeReturning: l10n.enrollmentDashboardTypeRe,
          unknownAgent: l10n.enrollmentDashboardDayListUnknownAgent,
          noHour: l10n.enrollmentDashboardDayListNoHour,
          subtitle: l10n.enrollmentDashboardDayPdfSubtitle,
          footer: l10n.enrollmentDashboardDayPdfFooter,
        ),
      );

      // Composé AVANT d'ouvrir le spouleur, comme le classement par niveau.
      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: l10n.enrollmentDashboardDayListTitle,
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.showError(context, l10n.enrollmentDashboardPdfFailed);
    }
  }

  static Future<void> _copyDayEntries(
    BuildContext context, {
    required List<DayEnrollmentEntry> entries,
    required DateTime day,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final fileName = EnrollmentDayEntriesCsv.fileName(day);

    try {
      final csv = EnrollmentDayEntriesCsv.build(
        entries: entries,
        labels: CsvDayEntriesLabels(
          columnHour: l10n.enrollmentDashboardDayListColumnHour,
          columnLastName: l10n.enrollmentDashboardCsvColumnLastName,
          columnFirstName: l10n.enrollmentDashboardCsvColumnFirstName,
          columnGender: l10n.enrollmentDashboardCsvColumnGender,
          columnLevel: l10n.enrollmentDashboardDayListColumnLevel,
          columnCycle: l10n.enrollmentDashboardPdfColumnCycle,
          columnType: l10n.enrollmentDashboardDayListColumnType,
          columnRecordedBy: l10n.enrollmentDashboardDayListColumnRecordedBy,
          female: l10n.enrollmentDashboardGenderGirls,
          male: l10n.enrollmentDashboardGenderBoys,
          typeFirst: l10n.enrollmentDashboardTypeFirst,
          typeReturning: l10n.enrollmentDashboardTypeRe,
        ),
      );

      await Clipboard.setData(ClipboardData(text: csv));
      if (!context.mounted) return;
      AppSnackBar.showSuccess(
        context,
        l10n.enrollmentDashboardCsvCopied(fileName),
      );
    } catch (_) {
      if (!context.mounted) return;
      AppSnackBar.showError(context, l10n.enrollmentDashboardCsvFailed);
    }
  }
}
