import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_student_sheet_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_page_actions.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fiche/fee_control_student_sheet.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la fiche d'un élève (O4) depuis le tableau de bord : la fiche du
/// contrôle des frais (`FeeControlStudentSheet`), sur **tous** ses frais lus
/// sur l'appareil. « Marquer à renvoyer » mène au contrôle des frais, où le
/// marquage vit (R16).
///
/// L'élève absent de l'appareil (tablette pas encore synchronisée) : un
/// message, et la fiche ne s'ouvre pas.
Future<void> showRecoveryStudentSheet(
  BuildContext context, {
  required String academicYearId,
  required String studentId,
  required String displayName,
  required VoidCallback onOpenControl,
}) async {
  // Un double toucher pendant la lecture n'ouvre pas deux fiches.
  if (_opening) return;
  _opening = true;
  try {
    await _open(
      context,
      academicYearId: academicYearId,
      studentId: studentId,
      displayName: displayName,
      onOpenControl: onOpenControl,
    );
  } finally {
    _opening = false;
  }
}

var _opening = false;

Future<void> _open(
  BuildContext context, {
  required String academicYearId,
  required String studentId,
  required String displayName,
  required VoidCallback onOpenControl,
}) async {
  final l10n = AppLocalizations.of(context)!;
  // Lus AVANT l'attente : la fiche s'ouvre sur le navigateur racine, hors de
  // portée des blocs de la page.
  final titles = context.read<FeeSectionTitlesCubit>().state;
  final cubit = getIt<RecoveryStudentSheetCubit>();
  await cubit.load(academicYearId, studentId);
  final row = cubit.state.row;
  final loaded = cubit.state.status == RecoveryLoadStatus.success;
  await cubit.close();
  if (!context.mounted) return;
  if (!loaded || row == null) {
    AppSnackBar.showWarning(
      context,
      l10n.recoveryStudentSheetUnavailable(displayName),
    );
    return;
  }
  final openRecord = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => FeeControlStudentSheet(
      row: row,
      sectionTitles: titles,
      marked: false,
      onToggleMark: () {
        Navigator.of(dialogContext).pop(false);
        onOpenControl();
      },
      onOpenRecord: () => Navigator.of(dialogContext).pop(true),
    ),
  );
  if (openRecord != true || !context.mounted) return;
  openFinancialRecord(context, row, academicYearId);
}
