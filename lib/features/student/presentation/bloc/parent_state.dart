part of 'parent_bloc.dart';

const _undefinedParent = Object();

enum ParentUpdateStatus {
  initial,
  loading,
  success,
  failure,
  unlinkSuccess,
  unlinkFailure,
}

enum ParentOperation { none, update, create, unlink, emergencyContact }

class ParentState extends Equatable {
  final ParentUpdateStatus status;
  final ParentOperation operation;
  final ParentSummary? updatedParent;
  final String? errorMessage;

  /// L'échec vaut-il la peine d'être RETENTÉ à l'identique ?
  ///
  /// Vrai pour un `409` seulement : deux postes ont désigné en même temps, le
  /// serveur a tranché, et le rejeu converge. Tous les autres refus sont
  /// terminaux — proposer « Réessayer » y serait une invitation à reproduire
  /// exactement ce que le serveur vient de refuser.
  final bool retryable;

  const ParentState({
    required this.status,
    required this.operation,
    required this.updatedParent,
    required this.errorMessage,
    this.retryable = false,
  });

  const ParentState.initial()
    : status = ParentUpdateStatus.initial,
      operation = ParentOperation.none,
      updatedParent = null,
      errorMessage = null,
      retryable = false;

  ParentState copyWith({
    ParentUpdateStatus? status,
    ParentOperation? operation,
    Object? updatedParent = _undefinedParent,
    Object? errorMessage = _undefinedParent,
    bool? retryable,
  }) {
    return ParentState(
      retryable: retryable ?? this.retryable,
      status: status ?? this.status,
      operation: operation ?? this.operation,
      updatedParent: identical(updatedParent, _undefinedParent)
          ? this.updatedParent
          : updatedParent as ParentSummary?,
      errorMessage: identical(errorMessage, _undefinedParent)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
    status,
    operation,
    updatedParent,
    errorMessage,
    retryable,
  ];
}
