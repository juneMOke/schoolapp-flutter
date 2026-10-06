import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la feuille de choix d'une pièce et rend le geste retenu, ou `null` si
/// l'utilisateur l'a refermée.
///
/// [title] nomme la pièce attendue (« Pièce d'identité »). Avec
/// [cameraUnavailable], l'action Numériser disparaît au profit d'un message :
/// l'utilisateur garde toujours une issue, l'import.
Future<DocumentCaptureMode?> showDocumentCaptureSheet(
  BuildContext context, {
  required String title,
  bool cameraUnavailable = false,
  required DocumentCapturePolicy policy,
}) {
  return showModalBottomSheet<DocumentCaptureMode>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: AppRadius.card),
    ),
    builder: (_) => DocumentCaptureSheet(
      title: title,
      cameraUnavailable: cameraUnavailable,
      policy: policy,
    ),
  );
}

/// Contenu de la feuille : le nom de la pièce, les bornes acceptées, puis un
/// geste par ligne. Un tap referme la feuille en rendant le geste.
class DocumentCaptureSheet extends StatelessWidget {
  final String title;
  final bool cameraUnavailable;
  final DocumentCapturePolicy policy;

  const DocumentCaptureSheet({
    super.key,
    required this.title,
    this.cameraUnavailable = false,
    required this.policy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              policy.acceptsWord
                  ? l10n.documentCaptureLimitsWithWord(policy.maxMegabytes)
                  : l10n.documentCaptureLimits(policy.maxMegabytes),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (cameraUnavailable)
              _CameraUnavailableNotice(
                message: l10n.documentCaptureCameraUnavailable,
              )
            else
              _CaptureOption(
                icon: Icons.document_scanner_outlined,
                label: l10n.documentCaptureScan,
                hint: l10n.documentCaptureScanHint,
                mode: DocumentCaptureMode.scan,
              ),
            _CaptureOption(
              icon: Icons.photo_library_outlined,
              label: l10n.documentCaptureImportImage,
              hint: l10n.documentCaptureImportImageHint,
              mode: DocumentCaptureMode.importImage,
            ),
            _CaptureOption(
              icon: Icons.picture_as_pdf_outlined,
              label: policy.acceptsWord
                  ? l10n.documentCaptureImportFile
                  : l10n.documentCaptureImportPdf,
              hint: policy.acceptsWord
                  ? l10n.documentCaptureImportFileHint
                  : l10n.documentCaptureImportPdfHint,
              mode: DocumentCaptureMode.importPdf,
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final DocumentCaptureMode mode;

  const _CaptureOption({
    required this.icon,
    required this.label,
    required this.hint,
    required this.mode,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.brMd,
      onTap: () => Navigator.of(context).pop(mode),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: AppSpacing.xxxl,
              height: AppSpacing.xxxl,
              decoration: const BoxDecoration(
                color: AppColors.bleuArdoiseSoft,
                borderRadius: AppRadius.brMd,
              ),
              child: Icon(icon, color: AppColors.bleuArdoise),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.titleSmall),
                  Text(
                    hint,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CameraUnavailableNotice extends StatelessWidget {
  final String message;

  const _CameraUnavailableNotice({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.terreCuiteSoft,
        borderRadius: AppRadius.brMd,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.no_photography_outlined,
            color: AppColors.terreCuiteDark,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
