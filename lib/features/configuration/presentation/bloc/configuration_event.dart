part of 'configuration_bloc.dart';

sealed class ConfigurationEvent extends Equatable {
  const ConfigurationEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Ouverture de l'assistant : reprise du brouillon, puis chargement des deux
/// catalogues.
///
/// Les catalogues sont chargés **ici**, à l'entrée, et non à l'entrée de leur
/// étape. Le promoteur passe une à deux minutes sur les étapes 1 et 2 ; le
/// catalogue est donc là quand il arrive au cœur, et le point de fragilité
/// réseau se déplace vers un moment où rien n'est encore investi.
class ConfigurationStarted extends ConfigurationEvent {
  const ConfigurationStarted();
}

/// Saut vers une étape depuis le stepper. Un rang hors d'atteinte est ignoré.
class ConfigurationStepSelected extends ConfigurationEvent {
  final ConfigurationStep step;

  const ConfigurationStepSelected(this.step);

  @override
  List<Object?> get props => [step];
}

/// « Continuer » : valide l'étape courante et avance.
class ConfigurationContinueRequested extends ConfigurationEvent {
  const ConfigurationContinueRequested();
}

/// « Retour ».
class ConfigurationBackRequested extends ConfigurationEvent {
  const ConfigurationBackRequested();
}

/// « Enregistrer » : persiste le brouillon sans changer d'étape.
class ConfigurationSaveRequested extends ConfigurationEvent {
  const ConfigurationSaveRequested();
}

/// Le brouillon a changé — une case cochée, un compteur, un frais ajouté.
///
/// Déclenche une simulation en débit contrôlé quand le brouillon est
/// simulable : c'est elle qui rend les chiffres affichés.
class ConfigurationDraftChanged extends ConfigurationEvent {
  final ProvisioningRequest draft;

  /// Certaines modifications n'ont aucun effet sur le plan (le libellé d'un
  /// frais, par exemple) : les simuler ferait un aller-retour pour rien.
  final bool simulate;

  const ConfigurationDraftChanged(this.draft, {this.simulate = true});

  @override
  List<Object?> get props => [draft, simulate];
}

/// Relance après un échec — l'action de récupération de l'écran d'erreur.
class ConfigurationRetryRequested extends ConfigurationEvent {
  /// Un 422 « code inconnu » signale précisément un catalogue périmé : c'est le
  /// seul cas où il faut le relire plutôt que rejouer la simulation.
  final bool refreshCatalog;

  const ConfigurationRetryRequested({this.refreshCatalog = false});

  @override
  List<Object?> get props => [refreshCatalog];
}

/// Fin de la temporisation de simulation.
class ConfigurationSimulationRequested extends ConfigurationEvent {
  const ConfigurationSimulationRequested();
}

/// « Activer l'école » — **la seule écriture de structure de tout le parcours**.
///
/// Un appel, tout ou rien : cycles, niveaux, classes, cours et tarifs sont
/// écrits dans une transaction unique, ou rien ne l'est. Aucun appel partiel de
/// rattrapage en cas d'échec.
class ConfigurationActivationRequested extends ConfigurationEvent {
  const ConfigurationActivationRequested();
}

/// Le serveur refuse l'année parce qu'elle existe déjà (400 `BUSINESS_RULE`).
///
/// Purge le brouillon et revient à l'étape de l'année. Sans ce geste, l'agent
/// resterait devant un refus que « Réessayer » ne peut pas lever : le brouillon
/// rejouerait la même année à chaque tentative.
class ConfigurationYearConflictAcknowledged extends ConfigurationEvent {
  const ConfigurationYearConflictAcknowledged();
}
