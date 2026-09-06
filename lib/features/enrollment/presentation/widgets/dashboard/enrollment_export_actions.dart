import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';
import 'package:school_app_flutter/features/enrollment/presentation/export/enrollment_day_entries_csv.dart';
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
    return _ExportButton(
      icon: Icons.picture_as_pdf_outlined,
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

  /// Le bouton CSV de la liste du jour.
  static Widget dayEntriesCsv({
    required BuildContext context,
    required List<DayEnrollmentEntry> entries,
    required DateTime day,
  }) {
    final l10n = AppLocalizations.of(context)!;
    return _ExportButton(
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

/// Un bouton de sortie : icône **et** libellé, cible tactile de 44 dp.
///
/// Le libellé n'est pas décoratif — une icône seule laisse deviner ce qui va
/// se produire, et deux icônes voisines (imprimer, tableur) se confondent.
class _ExportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  const _ExportButton({
    required this.icon,
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: ExcludeSemantics(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppDimensions.spacingS),
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: AppDimensions.enrollmentDashboardTabMinHeight,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.spacingM,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: AppDimensions.detailMiniIconSize,
                      color: AppColors.bleuArdoise,
                    ),
                    const SizedBox(width: AppDimensions.spacingXS),
                    Text(
                      label,
                      style: AppTextStyles.action.copyWith(
                        color: AppColors.bleuArdoise,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
