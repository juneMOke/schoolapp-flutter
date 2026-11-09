import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_subject.dart';
import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/auth/module_access_registry.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_sheet_action.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/suspension/consultation_suspension.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_options.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/widgets/level_correction_action.dart';
import 'package:school_app_flutter/features/enrollment_suspension/domain/entities/suspension_candidate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les actions de dossier de la barre sombre d'une consultation :
/// « Désactiver » / « Réactiver », « Corriger le niveau », « Fiche
/// d'inscription », « Modifier ».
class EnrollmentConsultationActions extends StatelessWidget {
  final SuspensionCandidate candidate;

  /// Première inscription consultée, dossier complété.
  final bool offersSuspension;

  /// Tout dossier complété consulté, quel qu'en soit le type (D9).
  final bool offersSheet;

  /// Ouvre la correction ; `null` quand le dossier ne se corrige pas.
  final VoidCallback? onReedit;

  /// Ce que corrige « Corriger le niveau » ; `null` quand le geste n'est pas
  /// offert. Demande un [LevelCorrectionScope] au-dessus.
  final LevelCorrectionSubject? levelCorrection;

  /// Les niveaux de l'année, cibles possibles de la correction.
  final List<LevelOption> levels;

  const EnrollmentConsultationActions({
    super.key,
    required this.candidate,
    required this.offersSuspension,
    required this.offersSheet,
    required this.onReedit,
    this.levelCorrection,
    this.levels = const [],
  });

  @override
  Widget build(BuildContext context) {
    final onReedit = this.onReedit;
    final levelCorrection = this.levelCorrection;
    return Wrap(
      spacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (offersSuspension)
          ConsultationSuspensionAction(candidate: candidate),
        if (levelCorrection != null)
          LevelCorrectionAction(subject: levelCorrection, levels: levels),
        if (offersSheet)
          EnrollmentSheetAction(
            enrollmentId: candidate.target.enrollmentId,
            studentId: candidate.target.studentId,
            academicYearId: candidate.target.academicYearId,
          ),
        // Bouton PLEIN (terre cuite) et non un texte sur la barre sombre :
        // c'est la seule porte de sortie de la lecture seule.
        if (onReedit != null)
          PermissionGate.access(
            kEnrollmentSubmitAccess,
            child: EteeloButton.primary(
              label: AppLocalizations.of(context)!.enrollmentReeditAction,
              icon: Icons.edit_outlined,
              fullWidth: false,
              onPressed: onReedit,
            ),
          ),
      ],
    );
  }
}
