import 'package:school_app_flutter/features/enrollment_level_correction/domain/usecases/level_correction_use_cases.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_subject.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_adaptive_dialog.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_options.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/bloc/level_correction_gesture_cubit.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/widgets/level_correction_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le parcours « Corriger le niveau » : lire les classes, ouvrir la modale,
/// annoncer le geste posé. Rend `true` si une correction a été posée.
abstract final class LevelCorrectionFlow {
  static Future<bool> open(
    BuildContext context, {
    required LevelCorrectionSubject subject,
    required List<LevelOption> levels,
  }) async {
    final loaded = await getIt<LoadLevelCorrectionClassroomsUseCase>()(
      studentId: subject.studentId,
      academicYearId: subject.academicYearId,
    );
    if (!context.mounted) return false;
    final classrooms = loaded.fold((_) => null, (c) => c);
    if (classrooms == null) {
      AppSnackBar.showError(
        context,
        AppLocalizations.of(context)!.levelCorrectionWriteFailed,
      );
      return false;
    }
    final done = await showEteeloAdaptiveDialog<bool>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => getIt<LevelCorrectionGestureCubit>(),
        child: LevelCorrectionDialog(
          subject: subject,
          levels: levels,
          classrooms: classrooms,
        ),
      ),
    );
    if (done == true && context.mounted) {
      AppSnackBar.showSuccess(
        context,
        AppLocalizations.of(context)!.levelCorrectionDone,
      );
    }
    return done == true;
  }
}
