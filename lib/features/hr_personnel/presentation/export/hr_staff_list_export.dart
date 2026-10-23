import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/components/documents/printable_document.dart';
import 'package:school_app_flutter/core/formatters/local_date_time_format.dart';
import 'package:school_app_flutter/core/helpers/school_time.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/export/hr_staff_list_pdf.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le geste « PDF » de « Qui sont-ils » : composer la liste affichée, le dire,
/// puis l'ouvrir dans la visionneuse partagée (imprimer, enregistrer,
/// partager).
///
/// Le document est composé **avant** d'ouvrir l'aperçu : une composition
/// impossible se dit tout de suite par un toast, plutôt que par une fenêtre
/// qui se refermerait seule.
abstract final class HrStaffListExport {
  static Future<void> run(
    BuildContext context, {
    required List<StaffFileRow> rows,
    required HrRosterQuery query,
    required String today,
    DateTime Function() now = DateTime.now,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    // L'heure de l'école, comme sous un ticket : la mention ne bouge pas avec
    // le fuseau du poste.
    final issuedAt = SchoolTime.wallClock(now());
    final academicYear = context
        .read<AcademicYearContextBloc>()
        .state
        .context
        ?.academicYear
        .name;
    final schoolName = context.read<SchoolIdentityCubit>().state.school?.name;

    try {
      final bytes = await HrStaffListPdf.build(
        rows: rows,
        query: query,
        today: today,
        academicYear: academicYear,
        schoolName: schoolName,
        issuedDate: formatLocalDay(issuedAt),
        issuedTime: l10n.hrClockTime(
          _two(issuedAt.hour),
          _two(issuedAt.minute),
        ),
        l10n: l10n,
      );
      if (!context.mounted) return;
      AppSnackBar.showSuccess(
        context,
        l10n.hrPdfReady(l10n.hrAgentsCount(rows.length)),
      );
      await showEteeloDocumentViewer(
        context,
        title: l10n.hrPdfTitle,
        document: PrintableDocument(
          bytes: bytes,
          fileName: fileName(query, issuedAt),
        ),
      );
    } catch (_) {
      // Canal de plateforme absent, spouleur indisponible : les données sont
      // intactes, seul le geste a échoué.
      if (!context.mounted) return;
      AppSnackBar.showError(context, l10n.hrPdfFailed);
    }
  }

  /// `personnel[-categorie]-AAAAMMJJ.pdf` — un nom technique, stable d'une
  /// langue à l'autre.
  static String fileName(HrRosterQuery query, DateTime issuedAt) {
    final category = query.category;
    final day = '${issuedAt.year}${_two(issuedAt.month)}${_two(issuedAt.day)}';
    final parts = ['personnel', if (category != null) category.name, day];
    return '${parts.join('-')}.pdf';
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}
