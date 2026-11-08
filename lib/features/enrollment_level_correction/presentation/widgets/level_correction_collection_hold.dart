import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/usecases/level_correction_use_cases.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Garde du guichet (D7) : rend `true` si l'encaissement de l'élève peut
/// s'ouvrir, et sinon dit pourquoi.
///
/// Une lecture qui échoue **laisse passer** : la garde de l'écriture du
/// versement, dans la même transaction que lui, reste le vrai rempart. Fermer
/// la caisse sur une erreur de lecture la fermerait sans raison.
Future<bool> ensureCollectionNotHeldByLevelCorrection(
  BuildContext context, {
  required String studentId,
  required String academicYearId,
}) async {
  final result = await getIt<IsCollectionHeldByLevelCorrectionUseCase>()(
    studentId: studentId,
    academicYearId: academicYearId,
  );
  final held = result.fold((_) => false, (held) => held);
  if (!held) return true;
  if (context.mounted) {
    AppSnackBar.showWarning(
      context,
      AppLocalizations.of(context)!.levelCorrectionCollectionHeld,
    );
  }
  return false;
}
