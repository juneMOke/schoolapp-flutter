import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_form_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_confirmation_dialog.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/timetable/copy_source.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/bloc/class_timetable_cubit.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/timetable_copy_plan.dart';
import 'package:school_app_flutter/features/schedule/presentation/timetable/widgets/copy_timetable_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// I15 — « Copier… » : O3, puis O6 si le brouillon n'est pas vide, puis la
/// copie et son accusé.
Future<void> copyTimetable(
  BuildContext context,
  ClassTimetableCubit cubit,
) async {
  final view = cubit.state.view;
  if (view == null) return;
  final l10n = AppLocalizations.of(context)!;
  final sources = await cubit.copySources();
  if (!context.mounted) return;
  final source = await EteeloFormDialog.show<CopySource>(
    context,
    CopyTimetableDialog(target: view, sources: sources),
  );
  if (!context.mounted || source == null) return;
  final existing = view.draft.where((c) => !c.isEmpty).length;
  if (view.hasDraft && existing > 0) {
    final replace = await showAppConfirmationDialog(
      context: context,
      title: l10n.classTimetableCopyReplaceTitle,
      message: l10n.classTimetableCopyReplaceBody(
        view.classroom.name,
        existing,
      ),
      confirmLabel: l10n.classTimetableCopyReplace,
      cancelLabel: l10n.classTimetableCancel,
      isDestructive: true,
    );
    if (!context.mounted || !replace) return;
  }
  final taken = TimetableCopyPlan.of(view, source).result.taken;
  final result = await cubit.copyFrom(source);
  if (!context.mounted) return;
  result.fold(
    (_) => AppSnackBar.showError(context, l10n.classTimetableSaveFailed),
    (_) =>
        AppSnackBar.showSuccess(context, l10n.classTimetableSnackCopied(taken)),
  );
}
