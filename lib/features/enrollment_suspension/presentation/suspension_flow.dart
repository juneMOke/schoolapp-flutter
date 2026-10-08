import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/student_suspension.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_candidate.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/bloc/suspension_gesture_cubit.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/reactivate_dialog.dart';
import 'package:school_app_flutter/features/enrollment_suspension/presentation/widgets/suspend_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux parcours de la désactivation, tels que chaque écran les lance :
/// la modale, puis le toast. Rendent le nombre d'élèves touchés (0 si la
/// modale a été fermée).
abstract final class SuspensionFlow {
  /// Désactive [candidates] après confirmation. [doneMessage] remplace le
  /// toast par défaut (« Élève désactivé · retiré de l'effectif » des
  /// classes).
  static Future<int> suspend(
    BuildContext context,
    List<SuspensionCandidate> candidates, {
    String Function(AppLocalizations l10n, int count)? doneMessage,
  }) async {
    final count = await _open(
      context,
      SuspendDialog(candidates: candidates, today: DateTime.now()),
    );
    if (count > 0 && context.mounted) {
      final l10n = AppLocalizations.of(context)!;
      AppSnackBar.showSuccess(
        context,
        doneMessage?.call(l10n, count) ?? l10n.suspensionDone(count),
      );
    }
    return count;
  }

  /// Réactive [candidates] après confirmation ; [suspension] nourrit le
  /// rappel « depuis quand, pourquoi » d'un élève seul.
  static Future<int> reactivate(
    BuildContext context,
    List<SuspensionCandidate> candidates, {
    StudentSuspension? suspension,
  }) async {
    final count = await _open(
      context,
      ReactivateDialog(candidates: candidates, suspension: suspension),
    );
    if (count > 0 && context.mounted) {
      AppSnackBar.showSuccess(
        context,
        AppLocalizations.of(context)!.reactivationDone(count),
      );
    }
    return count;
  }

  static Future<int> _open(BuildContext context, Widget dialog) async {
    final count = await showDialog<int>(
      context: context,
      builder: (_) => BlocProvider(
        create: (_) => getIt<SuspensionGestureCubit>(),
        child: dialog,
      ),
    );
    return count ?? 0;
  }
}
