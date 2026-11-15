import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/treasury_reports_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/helpers/treasury_failure_text.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux boutons d'un rapport (A5, B6) : le PDF s'ouvre dans la
/// visionneuse partagée (imprimer, partager le fichier : D29, pas de lien
/// public), la feuille Excel s'enregistre. Le fichier est généré à chaque
/// appel ; un rapport provisoire porte déjà son filigrane.
class ReportFormatButtons extends StatefulWidget {
  /// L'id du rapport (`RJ-20261022`…), qui est aussi sa référence imprimée.
  final String reportId;

  /// Le titre de la visionneuse.
  final String title;

  const ReportFormatButtons({
    super.key,
    required this.reportId,
    required this.title,
  });

  @override
  State<ReportFormatButtons> createState() => _ReportFormatButtonsState();
}

class _ReportFormatButtonsState extends State<ReportFormatButtons> {
  CashReportFormat? _busy;

  Future<void> _open(CashReportFormat format) async {
    if (_busy != null) return;
    // Pris AVANT l'appel : si la barre change de journée pendant le
    // chargement, le fichier reçu garde son propre titre.
    final id = widget.reportId;
    final title = widget.title;
    setState(() => _busy = format);
    final result = await GetIt.instance<TreasuryReportsRepository>().file(
      id,
      format,
    );
    if (!mounted) return;
    await result.fold(_refused, (file) => _deliver(file, id, title));
    if (mounted) setState(() => _busy = null);
  }

  Future<void> _refused(Failure failure) async {
    final l10n = AppLocalizations.of(context)!;
    AppSnackBar.showError(
      context,
      failure is TooManyRequestsFailure
          ? l10n.treasuryReportBusy
          : l10n.treasurySaveFailed(l10n.treasuryFailureReason(failure)),
    );
  }

  Future<void> _deliver(CashReportFile file, String id, String title) async {
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
          if (mounted) {
            AppSnackBar.showError(
              context,
              l10n.treasurySaveFailed(file.fileName),
            );
          }
          return;
        }
        // Le web télécharge sans rendre de chemin.
        if ((path != null || kIsWeb) && mounted) {
          AppSnackBar.showSuccess(
            context,
            l10n.treasuryReportSaved(file.fileName),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _FormatButton(
          label: l10n.treasuryReportPdf,
          tooltip: l10n.treasuryReportOpenPdf,
          icon: Icons.description_outlined,
          ink: AppColors.error,
          busy: _busy == CashReportFormat.pdf,
          onPressed: _busy == null ? () => _open(CashReportFormat.pdf) : null,
        ),
        _FormatButton(
          label: l10n.treasuryReportExcel,
          tooltip: l10n.treasuryReportOpenExcel,
          icon: Icons.grid_on,
          ink: AppColors.success,
          busy: _busy == CashReportFormat.xlsx,
          onPressed: _busy == null ? () => _open(CashReportFormat.xlsx) : null,
        ),
      ],
    );
  }
}

class _FormatButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final IconData icon;
  final Color ink;
  final bool busy;
  final VoidCallback? onPressed;

  const _FormatButton({
    required this.label,
    required this.tooltip,
    required this.icon,
    required this.ink,
    required this.busy,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: ink,
        side: BorderSide(color: ink.withValues(alpha: 0.25)),
        minimumSize: const Size(0, AppDimensions.minTouchTarget),
      ),
      onPressed: onPressed,
      icon: busy
          ? const SizedBox.square(
              dimension: AppSpacing.lg,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
    ),
  );
}
