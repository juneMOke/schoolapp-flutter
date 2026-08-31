part of 'configuration_bloc.dart';

/// Les cinq étapes de la mise en service.
///
/// L'ordre est celui du parcours, et il porte des dépendances réelles : la
/// simulation valide l'année avant tout le reste, et l'assiette des frais se
/// choisit parmi les niveaux que l'étape 3 a ouverts.
enum ConfigurationStep {
  school,
  academicYear,
  structure,
  fees,
  activation;

  int get rank => index;

  static const int count = 5;
}

/// Où en est le chargement de l'étape affichée.
enum ConfigurationStatus {
  /// Rien n'a encore été demandé.
  initial,

  /// Catalogue, identité ou simulation en vol — squelettes à l'écran.
  loading,

  /// Données en main.
  ready,

  /// Échec : le corps de l'étape cède la place au bloc d'erreur, et la barre de
  /// pied est neutralisée.
  failure,
}

/// État de l'assistant de mise en service.
class ConfigurationState extends Equatable {
  final ConfigurationStatus status;

  /// Étape affichée.
  final ConfigurationStep step;

  /// Rang le plus avancé jamais atteint — il ne recule pas.
  final int maxStep;

  /// Étapes explicitement validées.
  final Set<int> doneSteps;

  /// Le brouillon en construction. Seule l'étape 1 écrit hors de lui.
  final ProvisioningRequest draft;

  /// Catalogue servi, `null` tant qu'il n'a pas été chargé.
  final ProvisioningCatalog? catalog;

  /// Types de frais servis.
  final List<FeeCodeOption> feeCodes;

  /// Dernier plan rendu par la simulation. **Source unique de tous les chiffres
  /// affichés à partir de l'étape 3** — rien n'est recalculé localement.
  final ProvisioningPlan? plan;

  /// Une simulation est en vol. Distinct de [ConfigurationStatus.loading] :
  /// l'écran reste utilisable pendant qu'elle tourne, seuls les totaux et le
  /// pied attendent.
  final bool isSimulating;

  /// Échec courant, à rendre dans la carte de l'étape.
  final Failure? failure;

  /// Le brouillon a changé depuis le dernier enregistrement.
  final bool isDirty;

  /// Un enregistrement vient d'aboutir — la coche du pied, jusqu'à la
  /// modification suivante ou au changement d'étape.
  final bool justSaved;

  /// L'activation est en vol.
  final bool isActivating;

  /// L'école est en service : le plan rendu par l'activation, avec ses
  /// identifiants. `null` tant que rien n'a été activé.
  ///
  /// Distinct de [plan], qui reste celui de la simulation : c'est ce qui permet
  /// à l'écran de succès de citer ce qui a réellement été écrit.
  final ProvisioningPlan? activatedPlan;

  const ConfigurationState({
    this.status = ConfigurationStatus.initial,
    this.step = ConfigurationStep.school,
    this.maxStep = 0,
    this.doneSteps = const <int>{},
    this.draft = ProvisioningRequest.empty,
    this.catalog,
    this.feeCodes = const <FeeCodeOption>[],
    this.plan,
    this.isSimulating = false,
    this.failure,
    this.isDirty = false,
    this.justSaved = false,
    this.isActivating = false,
    this.activatedPlan,
  });

  /// Progression du stepper, dans le régime jalonné : on revient sur tout ce
  /// qu'on a atteint, et sur toute étape validée.
  WizardStepProgression get progression => WizardStepProgression(
    stepCount: ConfigurationStep.count,
    currentStep: step.rank,
    maxStep: maxStep,
    doneSteps: doneSteps,
  );

  bool get isLoading => status == ConfigurationStatus.loading;

  bool get hasFailure => status == ConfigurationStatus.failure;

  /// Chiffres du plan, ou des zéros tant qu'aucune simulation n'a répondu.
  ///
  /// Zéro et non « — » : l'étape 3 bascule en état vide sur `classrooms == 0`,
  /// et c'est le comportement juste avant qu'on ait coché quoi que ce soit.
  ProvisioningCounts get counts => plan?.counts ?? ProvisioningCounts.zero;

  /// L'école est en service.
  bool get isActivated => activatedPlan != null;

  /// Les quatre contrôles de l'écran d'activation.
  ///
  /// Ils portent sur le PLAN, jamais sur les cases cochées : l'activation
  /// rejoue exactement le calcul de la simulation, et c'est ce que le plan
  /// annonce qui sera écrit.
  bool get hasDatedYear => draft.academicYear?.hasValidRange ?? false;

  bool get hasClassrooms => counts.classrooms > 0;

  bool get hasFees => draft.fees.isNotEmpty;

  ConfigurationState copyWith({
    ConfigurationStatus? status,
    ConfigurationStep? step,
    int? maxStep,
    Set<int>? doneSteps,
    ProvisioningRequest? draft,
    ProvisioningCatalog? catalog,
    List<FeeCodeOption>? feeCodes,
    Object? plan = _unchanged,
    bool? isSimulating,
    Object? failure = _unchanged,
    bool? isDirty,
    bool? justSaved,
    bool? isActivating,
    ProvisioningPlan? activatedPlan,
  }) {
    return ConfigurationState(
      status: status ?? this.status,
      step: step ?? this.step,
      maxStep: maxStep ?? this.maxStep,
      doneSteps: doneSteps ?? this.doneSteps,
      draft: draft ?? this.draft,
      catalog: catalog ?? this.catalog,
      feeCodes: feeCodes ?? this.feeCodes,
      plan: identical(plan, _unchanged) ? this.plan : plan as ProvisioningPlan?,
      isSimulating: isSimulating ?? this.isSimulating,
      failure: identical(failure, _unchanged)
          ? this.failure
          : failure as Failure?,
      isDirty: isDirty ?? this.isDirty,
      justSaved: justSaved ?? this.justSaved,
      isActivating: isActivating ?? this.isActivating,
      activatedPlan: activatedPlan ?? this.activatedPlan,
    );
  }

  static const Object _unchanged = Object();

  @override
  List<Object?> get props => [
    status,
    step,
    maxStep,
    doneSteps,
    draft,
    catalog,
    feeCodes,
    plan,
    isSimulating,
    failure,
    isDirty,
    justSaved,
    isActivating,
    activatedPlan,
  ];
}
