part of 'academic_year_context_bloc.dart';

enum AcademicYearContextLoadStatus { initial, loading, success, failure }

class AcademicYearContextState extends Equatable {
  final AcademicYearContextLoadStatus status;
  final AcademicYearContext? context;
  final String? errorMessage;

  /// Un échec d'authentification (401/403) sur le pull référentiel signifie
  /// que la session n'est plus valide côté serveur → `main.dart` déclenchera
  /// un logout (même rôle que l'ex-`BootstrapState.sessionExpired`).
  final bool sessionExpired;

  const AcademicYearContextState({
    required this.status,
    this.context,
    this.errorMessage,
    this.sessionExpired = false,
  });

  const AcademicYearContextState.initial()
    : status = AcademicYearContextLoadStatus.initial,
      context = null,
      errorMessage = null,
      sessionExpired = false;

  bool get hasData => context != null;

  /// Bloque la navigation tant qu'aucune donnée n'est disponible ET qu'on
  /// n'est pas déjà en échec définitif (sinon c'est l'ErrorView qui prend le
  /// relais) — même formule que l'ex-`BootstrapState.blocksNavigation`.
  bool get blocksNavigation =>
      !hasData && status != AcademicYearContextLoadStatus.failure;

  /// Seul cas réellement bloquant : aucune donnée + échec → ErrorView.
  bool get hasBlockingFailure =>
      !hasData && status == AcademicYearContextLoadStatus.failure;

  AcademicYearContextState copyWith({
    AcademicYearContextLoadStatus? status,
    Object? context = const Object(),
    Object? errorMessage = const Object(),
    bool? sessionExpired,
  }) {
    return AcademicYearContextState(
      status: status ?? this.status,
      context: identical(context, const Object())
          ? this.context
          : context as AcademicYearContext?,
      errorMessage: identical(errorMessage, const Object())
          ? this.errorMessage
          : errorMessage as String?,
      sessionExpired: sessionExpired ?? this.sessionExpired,
    );
  }

  @override
  List<Object?> get props => [status, context, errorMessage, sessionExpired];
}
