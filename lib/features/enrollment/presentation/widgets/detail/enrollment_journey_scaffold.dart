import 'package:flutter/material.dart';
import 'package:school_app_flutter/features/enrollment/presentation/context/enrollment_detail_policy.dart'
    show EnrollmentWizardStep;
import 'package:school_app_flutter/features/enrollment/presentation/widgets/detail/enrollment_journey_app_bar.dart';

/// Coquille commune des vues du parcours détail (lecture seule / consultation
/// Première inscription / brouillon local) : un `Scaffold` surmonté de
/// l'en-tête [EnrollmentJourneyAppBar]. L'en-tête déclare déjà sa hauteur
/// préférée (`PreferredSizeWidget`), d'où l'absence de `PreferredSize`/hauteur
/// codée en dur ici. `totalSteps` est toujours le nombre d'étapes du wizard.
class EnrollmentJourneyScaffold extends StatelessWidget {
  final String modeLabel;
  final String studentDisplayName;
  final int currentStep;
  final Widget body;

  /// Sortie déléguée (retour + fermeture de l'app bar) — voir
  /// [EnrollmentJourneyAppBar.onExitRequested].
  final VoidCallback? onExitRequested;

  /// Action de niveau dossier relayée à l'en-tête (voir
  /// [EnrollmentJourneyAppBar.action]).
  final Widget? action;

  const EnrollmentJourneyScaffold({
    super.key,
    required this.modeLabel,
    required this.studentDisplayName,
    required this.currentStep,
    required this.body,
    this.onExitRequested,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: EnrollmentJourneyAppBar(
        modeLabel: modeLabel,
        studentDisplayName: studentDisplayName,
        currentStep: currentStep,
        totalSteps: EnrollmentWizardStep.values.length,
        onExitRequested: onExitRequested,
        action: action,
      ),
      body: body,
    );
  }
}
