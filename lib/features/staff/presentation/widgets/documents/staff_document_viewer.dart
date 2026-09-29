import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_content.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Montre une pièce du dossier : un PDF dans la visionneuse partagée, une
/// photo en plein écran, zoomable.
///
/// Jamais de partage : une pièce d'identité ou un diplôme ne quitte pas la
/// tablette par ce geste.
Future<void> showStaffDocumentViewer(
  BuildContext context, {
  required String title,
  required StaffDocumentContent content,
}) {
  if (content.isPdf) {
    return showEteeloDocumentViewer(
      context,
      title: title,
      document: PrintableDocument(
        bytes: content.bytes,
        fileName: content.fileName,
      ),
      canShare: false,
    );
  }
  return showDialog<void>(
    context: context,
    builder: (_) => StaffImageViewer(title: title, content: content),
  );
}

/// Une photo de pièce, plein écran, zoomable.
class StaffImageViewer extends StatelessWidget {
  final String title;
  final StaffDocumentContent content;

  const StaffImageViewer({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog.fullscreen(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  tooltip: l10n.staffDocumentClose,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Expanded(
            child: InteractiveViewer(
              maxScale: 5,
              child: Center(
                child: Image.memory(
                  content.bytes,
                  fit: BoxFit.contain,
                  semanticLabel: title,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
