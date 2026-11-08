import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/academic_year/domain/entities/academic_year_context.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_entities.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/local_enrollment_detail_mapper.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_intent.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_consultation_actions.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_detail_content_shell.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_journey_scaffold.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/enrollment_stepper_scope.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/level_correction/consultation_level_correction.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/photo/enrollment_photo_avatar.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/suspension/consultation_suspension.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/widgets/level_correction_action.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/widgets/level_correction_banner.dart';

/// Vue d'un dossier local rendue par le stepper : consultation lecture seule,
/// ou CORRECTION d'un dossier complété — même agrégat, même écran, seule la
/// politique ([detailPolicy]) change, et avec elle ce qui est éditable.
///
/// Porte les gestes de la consultation (désactivation, fiche, correction de
/// niveau) et leurs bandeaux ; la page ne fait que dire lesquels sont offerts.
class EnrollmentLocalConsultationView extends StatelessWidget {
  final LocalEnrollmentDetail local;
  final EnrollmentDetailIntent intent;
  final EnrollmentDetailPolicy detailPolicy;
  final String modeLabel;
  final String Function(EnrollmentDetail detail) displayName;
  final int currentStep;
  final ValueChanged<int> onStepChanged;

  /// Sortie confirmée, quand une correction n'a encore rien enregistré.
  final VoidCallback? onExitRequested;
  final VoidCallback? onReedit;
  final bool offersSuspension;
  final bool offersSheet;
  final bool offersLevelCorrection;

  /// La correction de niveau vient de descendre : le dossier est à relire.
  final VoidCallback onLevelCorrectionSettled;

  const EnrollmentLocalConsultationView({
    super.key,
    required this.local,
    required this.intent,
    required this.detailPolicy,
    required this.modeLabel,
    required this.displayName,
    required this.currentStep,
    required this.onStepChanged,
    required this.onLevelCorrectionSettled,
    this.onExitRequested,
    this.onReedit,
    this.offersSuspension = false,
    this.offersSheet = false,
    this.offersLevelCorrection = false,
  });

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
        builder: (context, academicYearState) =>
            _build(academicYearState.context),
      );

  Widget _build(AcademicYearContext? yearContext) {
    final detail = mapLocalToEnrollmentDetail(
      local,
      levels: schoolLevelsFromAcademicYearContext(yearContext),
      groups: schoolLevelGroupsFromAcademicYearContext(yearContext),
    );
    final candidate = consultationCandidate(local);
    final levelOptions = levelOptionsFromAcademicYearContext(yearContext);
    final enrollmentId = candidate.target.enrollmentId;
    return ConsultationSuspensionScope(
      enrollmentId: enrollmentId,
      child: LevelCorrectionScope(
        enrollmentId: enrollmentId,
        onSettled: onLevelCorrectionSettled,
        child: EnrollmentJourneyScaffold(
          modeLabel: modeLabel,
          studentDisplayName: displayName(detail),
          currentStep: currentStep,
          avatar: enrollmentPhotoAvatar(detail),
          onExitRequested: onExitRequested,
          // Bouton PLEIN (terre cuite) et non un texte sur la barre sombre :
          // c'est la seule porte de sortie de la lecture seule, et un libellé
          // posé sur un dégradé bleu se lit comme un titre, pas comme une
          // action — le guichet ne le voyait pas.
          action: EnrollmentConsultationActions(
            candidate: candidate,
            offersSuspension: offersSuspension,
            offersSheet: offersSheet,
            onReedit: onReedit,
            levelCorrection: offersLevelCorrection
                ? consultationLevelCorrectionSubject(local, levelOptions)
                : null,
            levels: levelOptions,
          ),
          body: EnrollmentDetailContentShell(
            child: EnrollmentStepperScope(
              enrollmentDetail: detail,
              detailIntent: intent,
              detailPolicy: detailPolicy,
              onStepChanged: onStepChanged,
              correctionOffered: onReedit != null,
              statusBanner: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConsultationSuspendedBanner(candidate: candidate),
                  LevelCorrectionBanner(
                    levelName: levelNameResolver(levelOptions),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
