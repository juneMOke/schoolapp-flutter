import 'package:equatable/equatable.dart';

/// État d'affichage d'une étape dans un stepper.
class WizardStepStatus extends Equatable {
  /// Rang de l'étape, à partir de 0.
  final int index;

  /// L'étape que l'utilisateur regarde.
  final bool isCurrent;

  /// L'étape est franchie : elle porte une coche, et le trait qui la relie à la
  /// suivante est actif.
  final bool isDone;

  /// L'étape est atteignable d'un tap depuis le stepper.
  final bool canTap;

  const WizardStepStatus({
    required this.index,
    required this.isCurrent,
    required this.isDone,
    required this.canTap,
  });

  @override
  List<Object?> get props => [index, isCurrent, isDone, canTap];
}

/// Mécanique commune aux assistants de l'application : qui est franchi, qui est
/// atteignable, et jusqu'où le retour en arrière est permis.
///
/// **Une seule mécanique, plusieurs habillages.** Le stepper d'inscription est
/// une bande claire sous l'AppBar, celui de la mise en service une rangée de
/// pastilles sur fond sombre : ils ne partagent aucun pixel. Ce qu'ils
/// partagent, c'est la règle — et c'est elle qui aurait divergé au premier
/// amendement si chacun l'avait recalculée dans son `build`.
///
/// Deux régimes, selon ce que l'assistant sait de lui-même :
///
/// - **linéaire** ([WizardStepProgression.linear]) : on revient librement en
///   arrière, on n'avance pas au-delà de l'étape courante. C'est le parcours
///   d'inscription, où chaque étape conditionne la suivante.
/// - **jalonné** ([WizardStepProgression.new]) : on revient sur tout ce qu'on a
///   déjà atteint, et sur toute étape déjà validée. C'est la mise en service,
///   dont le stepper reste navigable une fois l'assistant parcouru.
class WizardStepProgression extends Equatable {
  /// Nombre total d'étapes.
  final int stepCount;

  /// Étape affichée, à partir de 0.
  final int currentStep;

  /// Rang le plus avancé jamais atteint. Il ne recule pas quand l'utilisateur
  /// revient en arrière : c'est ce qui distingue « déjà vu » de « en cours ».
  final int maxStep;

  /// Étapes explicitement validées, par rang. Une étape validée reste
  /// atteignable même si elle précède [maxStep] — et surtout, elle porte sa
  /// coche indépendamment du rang où l'utilisateur se trouve.
  final Set<int> doneSteps;

  const WizardStepProgression({
    required this.stepCount,
    required this.currentStep,
    required this.maxStep,
    this.doneSteps = const <int>{},
  });

  /// Régime linéaire : tout ce qui précède l'étape courante est franchi, rien
  /// au-delà n'est atteignable.
  const WizardStepProgression.linear({
    required int stepCount,
    required int currentStep,
  }) : this(
         stepCount: stepCount,
         currentStep: currentStep,
         maxStep: currentStep,
       );

  /// État de l'étape de rang [index].
  WizardStepStatus statusAt(int index) {
    final isCurrent = index == currentStep;
    // Une étape est franchie si on l'a dépassée, ou si elle s'est déclarée
    // valide. Le second cas compte : en revenant à l'étape 2 d'un assistant
    // parcouru jusqu'au bout, les étapes 3 et 4 restent franchies — les rendre
    // « à venir » effacerait un travail qui existe.
    final isDone =
        !isCurrent && (index < currentStep || doneSteps.contains(index));
    return WizardStepStatus(
      index: index,
      isCurrent: isCurrent,
      isDone: isDone,
      // `index <= maxStep` et non `<= currentStep` : le saut avant reste
      // interdit tant qu'une étape n'a pas été atteinte une première fois, mais
      // revenir en arrière ne doit pas refermer ce qu'on avait ouvert.
      canTap:
          index <= currentStep || index <= maxStep || doneSteps.contains(index),
    );
  }

  /// État de toutes les étapes, dans l'ordre.
  List<WizardStepStatus> get statuses =>
      List<WizardStepStatus>.generate(stepCount, statusAt, growable: false);

  /// Le trait entre [index] et l'étape suivante est actif — vert — seulement si
  /// **les deux** sont franchies. Un trait qui verdit à moitié promet une
  /// progression qui n'a pas eu lieu.
  bool connectorAfter(int index) {
    if (index >= stepCount - 1) return false;
    return statusAt(index).isDone && statusAt(index + 1).isDone;
  }

  /// Progression pour une barre continue, entre 0 et 1.
  double get progress {
    if (stepCount <= 1) return 1;
    return (currentStep / (stepCount - 1)).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [stepCount, currentStep, maxStep, doneSteps];
}
