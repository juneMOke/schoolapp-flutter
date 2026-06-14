import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_detail.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/disciplinary_case_summary.dart';

const _undefined = Object();

enum DisciplinaryCaseStatusState { initial, loading, success, failure }

enum DisciplinaryCaseErrorType {
  none,
  network,
  notFound,
  validation,
  unauthorized,
  forbidden,
  invalidCredentials,
  server,
  storage,
  auth,
  unknown,
}

class DisciplinaryCaseState extends Equatable {
  final DisciplinaryCaseStatusState listStatus;
  final List<DisciplinaryCaseSummary> cases;
  final DisciplinaryCaseErrorType listErrorType;

  final DisciplinaryCaseStatusState detailStatus;
  final DisciplinaryCaseDetail? selectedCase;
  final DisciplinaryCaseErrorType detailErrorType;

  final DisciplinaryCaseStatusState createStatus;
  final DisciplinaryCaseSummary? createdCase;
  final DisciplinaryCaseErrorType createErrorType;

  const DisciplinaryCaseState({
    this.listStatus = DisciplinaryCaseStatusState.initial,
    this.cases = const [],
    this.listErrorType = DisciplinaryCaseErrorType.none,
    this.detailStatus = DisciplinaryCaseStatusState.initial,
    this.selectedCase,
    this.detailErrorType = DisciplinaryCaseErrorType.none,
    this.createStatus = DisciplinaryCaseStatusState.initial,
    this.createdCase,
    this.createErrorType = DisciplinaryCaseErrorType.none,
  });

  DisciplinaryCaseState copyWith({
    DisciplinaryCaseStatusState? listStatus,
    List<DisciplinaryCaseSummary>? cases,
    DisciplinaryCaseErrorType? listErrorType,
    DisciplinaryCaseStatusState? detailStatus,
    Object? selectedCase = _undefined,
    DisciplinaryCaseErrorType? detailErrorType,
    DisciplinaryCaseStatusState? createStatus,
    Object? createdCase = _undefined,
    DisciplinaryCaseErrorType? createErrorType,
  }) => DisciplinaryCaseState(
    listStatus: listStatus ?? this.listStatus,
    cases: cases ?? this.cases,
    listErrorType: listErrorType ?? this.listErrorType,
    detailStatus: detailStatus ?? this.detailStatus,
    selectedCase: identical(selectedCase, _undefined)
        ? this.selectedCase
        : selectedCase as DisciplinaryCaseDetail?,
    detailErrorType: detailErrorType ?? this.detailErrorType,
    createStatus: createStatus ?? this.createStatus,
    createdCase: identical(createdCase, _undefined)
        ? this.createdCase
        : createdCase as DisciplinaryCaseSummary?,
    createErrorType: createErrorType ?? this.createErrorType,
  );

  @override
  List<Object?> get props => [
    listStatus,
    cases,
    listErrorType,
    detailStatus,
    selectedCase,
    detailErrorType,
    createStatus,
    createdCase,
    createErrorType,
  ];
}
