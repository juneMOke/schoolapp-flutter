part of 'recouvrement_dashboard_bloc.dart';

sealed class RecouvrementDashboardEvent extends Equatable {
  const RecouvrementDashboardEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Charge les natures de frais facturées sur l'année — ce que l'écran offre à
/// la sélection. Émis au montage.
class RecouvrementFeeCodesRequested extends RecouvrementDashboardEvent {
  final String academicYearId;

  const RecouvrementFeeCodesRequested({required this.academicYearId});

  @override
  List<Object?> get props => [academicYearId];
}

/// Interroge la position de la population sur **une sélection** de frais.
///
/// Une sélection vide ne déclenche rien : l'écran refuse déjà de décocher la
/// dernière pastille, et le bloc ne se repose pas sur cette discipline.
class RecouvrementRequested extends RecouvrementDashboardEvent {
  final String academicYearId;

  /// Les natures retenues. L'ordre et les doublons sont indifférents : la
  /// requête les normalise.
  final List<String> feeCodes;

  /// `null` porte sur toute l'école.
  final String? schoolLevelGroupId;

  const RecouvrementRequested({
    required this.academicYearId,
    required this.feeCodes,
    this.schoolLevelGroupId,
  });

  @override
  List<Object?> get props => [academicYearId, feeCodes, schoolLevelGroupId];
}

/// Rejoue **la dernière lecture**, à l'identique — la reprise offerte par
/// l'état d'erreur. Sans `lastQuery`, ne fait rien : réessayer ne doit jamais
/// interroger autre chose que ce qui a échoué.
class RecouvrementRefreshRequested extends RecouvrementDashboardEvent {
  const RecouvrementRefreshRequested();
}
