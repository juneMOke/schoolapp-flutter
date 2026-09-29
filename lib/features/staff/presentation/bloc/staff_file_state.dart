import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';

/// Cartes ou tableau.
enum StaffViewMode { grid, list }

/// Automate de l'écran : premier chargement, prêt, jamais téléchargé, ou
/// panne de lecture.
enum StaffFileStatus {
  loading,
  ready,

  /// Le fichier n'a encore jamais été descendu sur cette tablette, et le
  /// réseau manque : il n'y a rien à montrer. Une fois en cache, une coupure
  /// n'est plus une erreur.
  neverSynced,
  failure,
}

class StaffFileState extends Equatable {
  final StaffFileStatus status;
  final StaffFileSnapshot snapshot;
  final StaffFileQuery query;
  final StaffViewMode viewMode;

  /// Le jour, `YYYY-MM-DD` : c'est lui qui dit quel contrat est en vigueur.
  final String today;
  final Failure? failure;

  const StaffFileState({
    required this.status,
    required this.snapshot,
    required this.query,
    required this.viewMode,
    required this.today,
    this.failure,
  });

  factory StaffFileState.initial({required String today}) => StaffFileState(
    status: StaffFileStatus.loading,
    snapshot: StaffFileSnapshot.empty,
    query: StaffFileQuery.none,
    viewMode: StaffViewMode.grid,
    today: today,
  );

  StaffFileState copyWith({
    StaffFileStatus? status,
    StaffFileSnapshot? snapshot,
    StaffFileQuery? query,
    StaffViewMode? viewMode,
    String? today,
    Failure? failure,
    bool clearFailure = false,
  }) => StaffFileState(
    status: status ?? this.status,
    snapshot: snapshot ?? this.snapshot,
    query: query ?? this.query,
    viewMode: viewMode ?? this.viewMode,
    today: today ?? this.today,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    status,
    snapshot,
    query,
    viewMode,
    today,
    failure,
  ];
}
