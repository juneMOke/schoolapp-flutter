part of 'fee_control_bloc.dart';

sealed class FeeControlEvent extends Equatable {
  const FeeControlEvent();

  @override
  List<Object?> get props => const [];
}

/// Charge la grille tarifaire du niveau choisi (émis à chaque changement de
/// niveau dans le formulaire).
class FeeControlTariffsRequested extends FeeControlEvent {
  final String academicYearId;
  final String schoolLevelGroupId;
  final String schoolLevelId;

  const FeeControlTariffsRequested({
    required this.academicYearId,
    required this.schoolLevelGroupId,
    required this.schoolLevelId,
  });

  @override
  List<Object?> get props => [
    academicYearId,
    schoolLevelGroupId,
    schoolLevelId,
  ];
}

/// Charge les classes du niveau choisi (maille sous-niveau du contrôle).
class FeeControlClassroomsRequested extends FeeControlEvent {
  final String academicYearId;
  final String schoolLevelId;

  const FeeControlClassroomsRequested({
    required this.academicYearId,
    required this.schoolLevelId,
  });

  @override
  List<Object?> get props => [academicYearId, schoolLevelId];
}

/// Lance la recherche : élèves inscrits de la classe, croisés avec leur
/// position sur les frais retenus, bornés à la situation demandée.
class FeeControlSearchRequested extends FeeControlEvent {
  final String academicYearId;
  final FeeControlSearchRequest request;

  /// Cours du jour, lu par la page. Il ne sert **qu'à arbitrer** : ordonner les
  /// lignes et comparer un plancher à un sac mixte. Aucun montant affiché n'est
  /// converti.
  final ExchangeRate? rate;

  final int page;
  final int size;

  const FeeControlSearchRequested({
    required this.academicYearId,
    required this.request,
    this.rate,
    this.page = 0,
    this.size = AppConstants.enrollmentDefaultPageSize,
  });

  @override
  List<Object?> get props => [academicYearId, request, rate, page, size];
}

/// Change la **situation recherchée** sans changer de périmètre — le geste
/// d'une tuile de compteur.
///
/// Aucune relecture : la population est déjà en mémoire, seule la coupe bouge.
class FeeControlSituationRequested extends FeeControlEvent {
  final FeeControlPaymentFilter filter;

  const FeeControlSituationRequested(this.filter);

  @override
  List<Object?> get props => [filter];
}

/// Change de page sur la liste courante (aucune relecture de la base).
class FeeControlPageRequested extends FeeControlEvent {
  final int page;

  const FeeControlPageRequested(this.page);

  @override
  List<Object?> get props => [page];
}

/// Rejoue la dernière recherche à l'identique (bouton « Réessayer »).
class FeeControlRefreshRequested extends FeeControlEvent {
  const FeeControlRefreshRequested();
}

/// Remet l'écran à l'état initial (carte d'invitation).
class FeeControlResetRequested extends FeeControlEvent {
  const FeeControlResetRequested();
}
