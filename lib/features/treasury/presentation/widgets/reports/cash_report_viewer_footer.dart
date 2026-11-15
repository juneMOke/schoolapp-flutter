import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_report.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les gestes de la visionneuse de rapport : imprimer et partager le PDF,
/// enregistrer la feuille Excel, fermer. Inactifs tant que le fichier
/// n'est pas arrivé.
class CashReportViewerFooter extends StatelessWidget {
  final CashReportFormat format;
  final CashReportFile? file;

  const CashReportViewerFooter({
    super.key,
    required this.format,
    required this.file,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final file = this.file;
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: Wrap(
        alignment: WrapAlignment.end,
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          if (format == CashReportFormat.pdf) ...[
            EteeloButton.secondary(
              label: l10n.documentViewerShareLabel,
              icon: Icons.share_outlined,
              onPressed: file == null
                  ? null
                  : () => _run(
                      context,
                      () => Printing.sharePdf(
                        bytes: file.bytes,
                        filename: file.fileName,
                      ),
                    ),
              fullWidth: false,
            ),
            EteeloButton.primary(
              label: l10n.documentViewerPrintLabel,
              icon: Icons.print_outlined,
              onPressed: file == null
                  ? null
                  : () => _run(
                      context,
                      () => Printing.layoutPdf(
                        onLayout: (_) => file.bytes,
                        name: file.fileName,
                      ),
                    ),
              fullWidth: false,
            ),
          ] else
            EteeloButton.primary(
              label: l10n.treasuryViewerSaveSheet,
              icon: Icons.download_outlined,
              onPressed: file == null ? null : () => _save(context, file),
              fullWidth: false,
            ),
          EteeloButton.ghost(
            label: l10n.documentViewerCloseLabel,
            onPressed: () => Navigator.of(context).maybePop(),
            fullWidth: false,
          ),
        ],
      ),
    );
  }

  /// Un geste de plateforme dont l'échec se voit : sans quoi l'appui ne
  /// produirait rien du tout.
  static Future<void> _run(
    BuildContext context,
    Future<Object?> Function() action,
  ) async {
    final message = AppLocalizations.of(context)!.documentViewerActionFailed;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await action();
    } catch (_) {
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  static Future<void> _save(BuildContext context, CashReportFile file) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      final path = await FilePicker.saveFile(
        fileName: file.fileName,
        bytes: file.bytes,
      );
      // Le web télécharge sans rendre de chemin.
      if (path != null || kIsWeb) {
        messenger?.showSnackBar(
          SnackBar(content: Text(l10n.treasuryReportSaved(file.fileName))),
        );
      }
    } catch (_) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.treasurySaveFailed(file.fileName))),
      );
    }
  }
}
