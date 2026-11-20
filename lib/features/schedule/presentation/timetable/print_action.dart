import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/documents/eteelo_document_viewer.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/schedule/data/timetable/timetable_editor.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// I25 — « Imprimer » (O7) : la pièce `ET` composée par le serveur, ouverte
/// dans la visionneuse partagée (aperçu, puis imprimer ou partager).
Future<void> printTimetable(
  BuildContext context,
  ClassTimetableCubit cubit,
) async {
  final view = cubit.state.view;
  if (view == null) return;
  final l10n = AppLocalizations.of(context)!;
  final result = await cubit.printPublished();
  if (!context.mounted) return;
  await result.fold(
    (f) async => AppSnackBar.showError(
      context,
      onRetry: f is TimetableRefusalFailure
          ? null
          : () => printTimetable(context, cubit),
      f is TimetableRefusalFailure
          ? l10n.classTimetableRefusal(f.code)
          : l10n.classTimetablePrintFailed,
    ),
    (document) => showEteeloDocumentViewer(
      context,
      title: l10n.classTimetablePrintTitle(view.classroom.name),
      document: document,
    ),
  );
}
