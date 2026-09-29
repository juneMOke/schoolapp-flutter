import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_view_mode.dart';

export 'package:school_app_flutter/features/staff/presentation/bloc/staff_view_mode.dart';

/// Automate de l'écran : premier chargement, prêt, ou panne de lecture.
///
/// Un fichier jamais téléchargé n'est **pas** un état à part : l'écran s'ouvre
/// sur ce que la tablette connaît — rien, ou les agents créés ici — et le dit
/// par un bandeau. Comme partout ailleurs, on travaille hors ligne dès la
/// première ouverture ; seule la lecture des autres agents attend le réseau.
enum StaffFileStatus { loading, ready, failure }

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
