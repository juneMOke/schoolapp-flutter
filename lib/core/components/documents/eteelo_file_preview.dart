import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Montre un fichier gardé sur la tablette : un PDF dans la visionneuse
/// partagée, une image en plein écran, zoomable. Rend `false` — sans rien
/// ouvrir — pour un type qui ne se prévisualise pas (un document Word).
///
/// Ni partage ni impression : une pièce ne quitte pas la tablette par ce
/// geste — le spouleur offre « Enregistrer en PDF ».
Future<bool> showEteeloFilePreview(
  BuildContext context, {
  required String title,
  required Uint8List bytes,
  required String mimeType,
  required String fileName,
}) async {
  if (mimeType == 'application/pdf') {
    await showEteeloDocumentViewer(
      context,
      title: title,
      document: PrintableDocument(bytes: bytes, fileName: fileName),
      canShare: false,
      canPrint: false,
    );
    return true;
  }
  if (mimeType.startsWith('image/')) {
    await showDialog<void>(
      context: context,
      builder: (_) => EteeloImageViewer(title: title, bytes: bytes),
    );
    return true;
  }
  return false;
}

/// Une image plein écran, zoomable.
class EteeloImageViewer extends StatelessWidget {
  final String title;
  final Uint8List bytes;

  const EteeloImageViewer({
    super.key,
    required this.title,
    required this.bytes,
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
                  tooltip: l10n.documentViewerCloseLabel,
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
                  bytes,
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
