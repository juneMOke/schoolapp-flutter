import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_subject.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_journey_pill_button.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_options.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/bloc/level_correction_status_cubit.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/level_correction_flow.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Fournit l'état de correction d'une inscription à l'action et au bandeau.
///
/// [onSettled] : la correction vient de descendre **sous les yeux** de
/// l'écran (passage observé à `settled`, jamais à la première lecture) — le
/// dossier affiché porte encore l'ancien niveau, et doit être relu. Sans quoi
/// l'action, rouverte, proposerait une correction partant d'un niveau périmé.
class LevelCorrectionScope extends StatelessWidget {
  final String enrollmentId;
  final VoidCallback? onSettled;
  final Widget child;

  const LevelCorrectionScope({
    super.key,
    required this.enrollmentId,
    this.onSettled,
    required this.child,
  });

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<LevelCorrectionStatusCubit>(param1: enrollmentId),
    child: BlocListener<LevelCorrectionStatusCubit, LevelCorrectionStatusState>(
      listenWhen: (previous, current) =>
          justSettled(previous.correction, current.correction),
      listener: (_, _) => onSettled?.call(),
      child: child,
    ),
  );

  /// Vrai quand la même correction passe à `settled` entre deux lectures.
  @visibleForTesting
  static bool justSettled(
    LevelCorrection? previous,
    LevelCorrection? current,
  ) =>
      previous != null &&
      current != null &&
      previous.id == current.id &&
      previous.status != LevelCorrectionStatus.settled &&
      current.status == LevelCorrectionStatus.settled;
}

/// « Corriger le niveau », en pilule sur la barre sombre d'un dossier
/// consulté. Masquée sans `enrollment.level.correct` : le geste part par
/// l'outbox, où un 403 est terminal. Éteinte tant qu'une correction attend ou
/// n'est pas encore descendue.
class LevelCorrectionAction extends StatelessWidget {
  final LevelCorrectionSubject subject;
  final List<LevelOption> levels;

  const LevelCorrectionAction({
    super.key,
    required this.subject,
    required this.levels,
  });

  @override
  Widget build(BuildContext context) {
    final pending = context.select<LevelCorrectionStatusCubit, bool>(
      (cubit) => cubit.state.blocksNewCorrection,
    );
    return PermissionGate.access(
      kEnrollmentLevelCorrectAccess,
      child: SessionWriteGate(
        child: EnrollmentJourneyPillButton(
          label: AppLocalizations.of(context)!.levelCorrectionAction,
          icon: Icons.swap_vert_rounded,
          onPressed: pending
              ? null
              : () => LevelCorrectionFlow.open(
                  context,
                  subject: subject,
                  levels: levels,
                ),
        ),
      ),
    );
  }
}
