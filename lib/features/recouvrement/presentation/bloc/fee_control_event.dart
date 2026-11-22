part of 'fee_control_bloc.dart';

sealed class FeeControlEvent extends Equatable {
  const FeeControlEvent();

  @override
  List<Object?> get props => const [];
}

/// Charge la grille tarifaire du niveau choisi (émis à chaque changement de
/// niveau dans le formulaire).
/// Charge le **catalogue** de l'écran : les natures de frais de l'année avec
/// leur(s) devise(s), et toutes les classes de l'année (champ Classe unique,
/// spec v2 R2). Rejoué par « Réessayer ».
class FeeControlCatalogRequested extends FeeControlEvent {
  final String academicYearId;

  const FeeControlCatalogRequested({required this.academicYearId});

  @override
  List<Object?> get props => [academicYearId];
}

class FeeControlSearchRequested extends FeeControlEvent {
  final String academicYearId;
  final FeeControlSearchRequest request;

  final int page;
  final int size;

  const FeeControlSearchRequested({
    required this.academicYearId,
    required this.request,
    this.page = 0,
    this.size = AppConstants.enrollmentDefaultPageSize,
  });

  @override
  List<Object?> get props => [academicYearId, request, page, size];
}

/// Change la **situation recherchée** sans changer de périmètre — le geste
/// d'une tuile de compteur.
///
/// Aucune relecture : la population est déjà en mémoire, seule la coupe bouge.
class FeeControlSituationRequested extends FeeControlEvent {
  final FeeControlPaymentFilter filter;

  /// Le montant du segment « a payé au moins… » ; ignoré ailleurs.
  final Money? threshold;

  const FeeControlSituationRequested(this.filter, {this.threshold});

  @override
  List<Object?> get props => [filter, threshold];
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
