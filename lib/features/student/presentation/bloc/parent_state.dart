part of 'parent_bloc.dart';

const _undefinedParent = Object();

enum ParentUpdateStatus { initial, loading, success, failure }

enum ParentOperation { none, update, create }

class ParentState extends Equatable {
  final ParentUpdateStatus status;
  final ParentOperation operation;
  final ParentSummary? updatedParent;
  final String? errorMessage;

  const ParentState({
    required this.status,
    required this.operation,
    required this.updatedParent,
    required this.errorMessage,
  });

  const ParentState.initial()
      : status = ParentUpdateStatus.initial,
        operation = ParentOperation.none,
        updatedParent = null,
        errorMessage = null;

  ParentState copyWith({
    ParentUpdateStatus? status,
    ParentOperation? operation,
    Object? updatedParent = _undefinedParent,
    Object? errorMessage = _undefinedParent,
  }) {
    return ParentState(
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
  List<Object?> get props => [status, operation, updatedParent, errorMessage];
}
