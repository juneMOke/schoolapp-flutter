part of 'academic_year_context_bloc.dart';

sealed class AcademicYearContextEvent extends Equatable {
  const AcademicYearContextEvent();

  @override
  List<Object?> get props => [];
}

/// Déclenché post-auth (`main.dart`) ou au montage d'une feature scope.
class AcademicYearContextRequested extends AcademicYearContextEvent {
  const AcademicYearContextRequested();
}

/// Bouton « Réessayer » de `SplashErrorView`.
class AcademicYearContextRetryRequested extends AcademicYearContextEvent {
  const AcademicYearContextRetryRequested();
}

/// Déclenché sur `AuthStatus.unauthenticated` (logout) : remet l'état à
/// initial pour qu'une session suivante (même device, école différente) ne
/// montre pas transitoirement le contexte du compte précédent.
class AcademicYearContextResetRequested extends AcademicYearContextEvent {
  const AcademicYearContextResetRequested();
}

/// Patch optimiste post-répartition (Classe) : le niveau [schoolLevelId] vient
/// d'être réparti en classes.
class AcademicYearContextSchoolLevelSplitPatched
    extends AcademicYearContextEvent {
  final String schoolLevelId;

  const AcademicYearContextSchoolLevelSplitPatched(this.schoolLevelId);

  @override
  List<Object?> get props => [schoolLevelId];
}
