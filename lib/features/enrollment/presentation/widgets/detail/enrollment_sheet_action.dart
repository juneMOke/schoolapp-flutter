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
class EnrollmentSheetAction extends StatefulWidget {
  final String enrollmentId;
  final String studentId;
  final String academicYearId;

  const EnrollmentSheetAction({
    super.key,
    required this.enrollmentId,
    required this.studentId,
    required this.academicYearId,
  });

  @override
  State<EnrollmentSheetAction> createState() => _EnrollmentSheetActionState();

  /// La fiche la plus récente dont la tablette détient les octets ; une fiche
  /// remplacée n'est jamais préférée à sa remplaçante.
  ///
  /// Une fiche corrigée garde son numéro, en édition suivante (back v0.17.0) :
  /// une fiche dont le numéro est porté par une ligne plus récente est donc
  /// remplacée, et ne ressort pas même quand les octets de sa remplaçante ont
  /// été évincés. Mieux vaut aucune fiche hors ligne qu'une fiche périmée
  /// remise comme valable.
  static EditiqueCacheEntry? latestKeptSheet(List<EditiqueCacheEntry> kept) {
    final sheets = [
      for (final e in kept)
        if (e.docType == EditiqueDocumentType.enrollmentSheet.code) e,
    ]..sort(_newestFirst);
    final newerNumbers = <String>{};
    for (final sheet in sheets) {
      final number = sheet.documentNumber;
      if (number != null && number.isNotEmpty && !newerNumbers.add(number)) {
        continue;
      }
      if (sheet.hasBytes) return sheet;
    }
    return null;
  }

  static int _newestFirst(EditiqueCacheEntry a, EditiqueCacheEntry b) {
    final byDay = (b.emittedAt ?? b.createdAt).compareTo(
      a.emittedAt ?? a.createdAt,
    );
    if (byDay != 0) return byDay;
    // Une fiche corrigée l'est souvent le jour même : à jour égal, c'est
    // l'édition qui dit la fiche en vigueur — jamais la stabilité du tri.
    final byEdition = (b.edition ?? 1).compareTo(a.edition ?? 1);
    return byEdition != 0 ? byEdition : b.createdAt.compareTo(a.createdAt);
  }
}

class _EnrollmentSheetActionState extends State<EnrollmentSheetAction> {
  /// Un second appui pendant l'ouverture n'émet pas une seconde fois.
  bool _busy = false;

  Future<void> _onPressed() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _open();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _open() async {
    final l10n = AppLocalizations.of(context)!;
    final enrollmentId = widget.enrollmentId;
    final studentId = widget.studentId;
    final academicYearId = widget.academicYearId;
    if (await getIt<ConnectivityService>().isOnline()) {
      if (!mounted) return;
      await showEditiqueEnrollmentSheetDialog(
        context,
        enrollmentId: enrollmentId,
        studentId: studentId,
        academicYearId: academicYearId,
      );
      return;
    }
    final kept = EnrollmentSheetAction.latestKeptSheet(
      await getIt<ListCachedDocumentsUseCase>()(
        studentId: studentId,
        academicYearId: academicYearId,
      ),
    );
    if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PermissionGate(
      requires: const [Perm.editiqueWrite, Perm.enrollmentRead],
      requiresAll: true,
      child: EnrollmentJourneyPillButton(
        label: l10n.enrollmentSheetAction,
        icon: Icons.print_outlined,
        onPressed: _busy ? null : _onPressed,
      ),
    );
  }
}
