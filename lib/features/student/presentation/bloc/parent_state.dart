part of 'parent_bloc.dart';

const _undefinedParent = Object();

enum ParentUpdateStatus { initial, loading, success, failure }

class ParentState extends Equatable {
  final ParentUpdateStatus status;
  final ParentSummary? updatedParent;
  final String? errorMessage;

  const ParentState({
    required this.status,
    required this.updatedParent,
    required this.errorMessage,
  });

  const ParentState.initial()
      : status = ParentUpdateStatus.initial,
        updatedParent = null,
        errorMessage = null;

  ParentState copyWith({
    ParentUpdateStatus? status,
    Object? updatedParent = _undefinedParent,
    Object? errorMessage = _undefinedParent,
  }) {
    return ParentState(
      status: status ?? this.status,
      updatedParent: identical(updatedParent, _undefinedParent)
          ? this.updatedParent
          : updatedParent as ParentSummary?,
      errorMessage: identical(errorMessage, _undefinedParent)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [status, updatedParent, errorMessage];
}
