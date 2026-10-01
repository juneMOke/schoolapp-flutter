import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document_type.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Une pièce du dossier : son libellé, où elle en est, et ce qu'on peut en
/// faire.
class StaffDocumentTile extends StatelessWidget {
  final StaffDocumentType type;

  /// La pièce courante de ce code, ou `null` : à verser.
  final StaffDocument? document;

  /// Exigée par le contrat en vigueur (ou commune à tous).
  final bool required;

  /// La fiche n'est pas encore accusée : une pièce versée attend qu'elle le
  /// soit (« bloquée par la fiche »).
  final bool memberPending;

  /// `null` quand le compte ne peut pas verser.
  final VoidCallback? onAdd;

  /// `null` quand le compte ne peut pas lire les pièces.
  final VoidCallback? onView;

  const StaffDocumentTile({
    super.key,
    required this.type,
    required this.document,
    required this.required,
    required this.memberPending,
    this.onAdd,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final (status, color) = _status(l10n);
    final add = onAdd;
    final view = onView;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.sm,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(type.label, style: AppTypography.titleSmall),
              Text(
                required
                    ? l10n.staffDocumentRequired
                    : l10n.staffDocumentOptional,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMutedAa,
                ),
              ),
              Text(
                status,
                style: AppTypography.bodySmall.copyWith(color: color),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              if (view != null && document != null)
                TextButton.icon(
                  onPressed: view,
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(l10n.staffDocumentView),
                ),
              if (add != null)
                TextButton.icon(
                  onPressed: add,
                  icon: const Icon(Icons.upload_file_outlined),
                  label: Text(
                    document == null
                        ? l10n.staffDocumentAdd
                        : l10n.staffDocumentReplace,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  (String, Color) _status(AppLocalizations l10n) {
    final document = this.document;
    if (document == null) {
      return (l10n.staffDocumentMissing, AppColors.staffPartialInk);
    }
    return switch (document.syncState) {
      RecordSyncState.synced => (
        l10n.staffDocumentFiled(_day(document.capturedAt)),
        AppColors.textSecondary,
      ),
      RecordSyncState.failed => (
        l10n.staffDocumentRejected(document.syncError ?? ''),
        AppColors.error,
      ),
      RecordSyncState.pending when memberPending => (
        l10n.staffDocumentWaitingMember,
        AppColors.textSecondary,
      ),
      RecordSyncState.pending => (
        l10n.staffDocumentPending,
        AppColors.textSecondary,
      ),
    };
  }

  /// L'instant de capture, à l'heure de la tablette.
  static String _day(String instant) {
    final parsed = DateTime.tryParse(instant);
    return parsed == null ? instant : formatLocalDateTime(parsed);
  }
}
