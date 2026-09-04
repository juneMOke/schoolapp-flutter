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
/// position sur le frais choisi, bornés au statut demandé.
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
