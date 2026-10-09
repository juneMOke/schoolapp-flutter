import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_cache_entry.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/list_cached_documents_use_case.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/editique_document_dialog.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_journey_pill_button.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Fiche d'inscription », en pilule sur la barre sombre d'un dossier
/// complété. En ligne, le serveur rend la fiche en vigueur (re-servie ou
/// rescellée) ; hors ligne, la dernière que la tablette a gardée.
class EnrollmentSheetAction extends StatelessWidget {
  final String enrollmentId;
  final String studentId;
  final String academicYearId;

  const EnrollmentSheetAction({
    super.key,
    required this.enrollmentId,
    required this.studentId,
    required this.academicYearId,
  });

  Future<void> _open(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    if (await getIt<ConnectivityService>().isOnline()) {
      if (!context.mounted) return;
      await showEditiqueEnrollmentSheetDialog(
        context,
        enrollmentId: enrollmentId,
        studentId: studentId,
        academicYearId: academicYearId,
      );
      return;
    }
    final kept = latestKeptSheet(
      await getIt<ListCachedDocumentsUseCase>()(
        studentId: studentId,
        academicYearId: academicYearId,
      ),
    );
    if (!context.mounted) return;
    if (kept == null) {
      AppSnackBar.showWarning(context, l10n.enrollmentSheetOfflineNone);
      return;
    }
    await showEditiqueRestitutionDialog(
      context,
      type: EditiqueDocumentType.enrollmentSheet,
      title: l10n.editiqueViewerSheetTitle,
      documentId: kept.documentId,
      documentNumber: kept.documentNumber,
      studentId: studentId,
      academicYearId: academicYearId,
    );
  }

  /// La fiche la plus récente dont la tablette détient les octets ; une fiche
  /// remplacée n'est jamais préférée à sa remplaçante.
  static EditiqueCacheEntry? latestKeptSheet(List<EditiqueCacheEntry> kept) {
    final sheets =
        [
          for (final e in kept)
            if (e.docType == EditiqueDocumentType.enrollmentSheet.code &&
                e.hasBytes)
              e,
        ]..sort(
          (a, b) => (b.emittedAt ?? b.createdAt).compareTo(
            a.emittedAt ?? a.createdAt,
          ),
        );
    return sheets.isEmpty ? null : sheets.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PermissionGate(
      requires: const [Perm.editiqueWrite, Perm.enrollmentRead],
      requiresAll: true,
      child: EnrollmentJourneyPillButton(
        label: l10n.enrollmentSheetAction,
        icon: Icons.print_outlined,
        onPressed: () => _open(context),
      ),
    );
  }
}
