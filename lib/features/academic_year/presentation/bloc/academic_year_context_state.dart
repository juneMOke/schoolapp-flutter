part of 'academic_year_context_bloc.dart';

enum AcademicYearContextLoadStatus { initial, loading, success, failure }

class AcademicYearContextState extends Equatable {
  final AcademicYearContextLoadStatus status;
  final AcademicYearContext? context;
  final String? errorMessage;

  /// Un **401** sur le pull référentiel signifie que la session n'est plus
  /// valide côté serveur → `main.dart` déclenchera un logout (même rôle que
  /// l'ex-`BootstrapState.sessionExpired`).
  ///
  /// Le 403 en est exclu depuis ADR-014 : voir [insufficientPermissions].
  final bool sessionExpired;

  /// Un **403** sur le pull référentiel : le compte est authentifié mais ne
  /// détient pas la permission exigée (ADR-014 §4). Rien à réessayer et rien à
  /// déconnecter — seul un changement de droits côté serveur y remédie.
  final bool insufficientPermissions;

  /// L'école n'a **pas encore été paramétrée** : le pull a abouti et le serveur
  /// ne connaît aucune année académique pour elle.
  ///
  /// Ni panne ni droit manquant — un établissement fraîchement souscrit. La
  /// distinction porte l'écran : ce cas-là ne propose pas « Réessayer » (rien
  /// dans ce geste ne crée une année) mais l'entrée dans l'assistant de
  /// configuration, pour qui détient la permission de paramétrer.
  final bool schoolNotProvisioned;

  const AcademicYearContextState({
    required this.status,
    this.context,
    this.errorMessage,
    this.sessionExpired = false,
    this.insufficientPermissions = false,
    this.schoolNotProvisioned = false,
  });

  const AcademicYearContextState.initial()
    : status = AcademicYearContextLoadStatus.initial,
      context = null,
      errorMessage = null,
      sessionExpired = false,
      insufficientPermissions = false,
      schoolNotProvisioned = false;

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
    bool? insufficientPermissions,
    bool? schoolNotProvisioned,
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
      insufficientPermissions:
          insufficientPermissions ?? this.insufficientPermissions,
      schoolNotProvisioned: schoolNotProvisioned ?? this.schoolNotProvisioned,
    );
  }

  @override
  List<Object?> get props => [
    status,
    context,
    errorMessage,
    sessionExpired,
    insufficientPermissions,
    schoolNotProvisioned,
  ];
}
