part of 'fee_control_dashboard_bloc.dart';

sealed class FeeControlDashboardEvent extends Equatable {
  const FeeControlDashboardEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Charge les natures de frais facturées sur l'année — ce que l'écran offre à
/// la sélection. Émis au montage.
class FeeControlDashboardFeeCodesRequested extends FeeControlDashboardEvent {
  final String academicYearId;

  const FeeControlDashboardFeeCodesRequested({required this.academicYearId});

  @override
  List<Object?> get props => [academicYearId];
}

/// Interroge la position de la population sur un frais.
class FeeControlDashboardRequested extends FeeControlDashboardEvent {
  final String academicYearId;
  final String feeCode;

  /// `null` porte sur toute l'école.
  final String? schoolLevelGroupId;

  const FeeControlDashboardRequested({
    required this.academicYearId,
    required this.feeCode,
    this.schoolLevelGroupId,
  });

  @override
  List<Object?> get props => [academicYearId, feeCode, schoolLevelGroupId];
}

/// Rejoue **la dernière lecture**, à l'identique — la reprise offerte par
/// l'état d'erreur. Sans `lastQuery`, ne fait rien : réessayer ne doit jamais
/// interroger autre chose que ce qui a échoué.
class FeeControlDashboardRefreshRequested extends FeeControlDashboardEvent {
  const FeeControlDashboardRefreshRequested();
}

/// Déplie un niveau en ses classes, ou le replie s'il l'était déjà.
///
/// Un seul niveau reste ouvert à la fois : on déplie celui qui décroche pour
/// voir laquelle de ses classes le tire, et cette question ne se pose pas sur
/// deux niveaux en même temps. En garder plusieurs ouverts n'ajouterait qu'un
/// état à tenir et des rosters à retenir.
class FeeControlDashboardGroupToggled extends FeeControlDashboardEvent {
  final String academicYearId;

  /// `null` — le groupe « niveau non renseigné » — n'est pas dépliable : sans
  /// niveau, il n'y a pas de classe où chercher.
  final String? schoolLevelId;

  const FeeControlDashboardGroupToggled({
    required this.academicYearId,
    required this.schoolLevelId,
  });

  @override
  List<Object?> get props => [academicYearId, schoolLevelId];
}
