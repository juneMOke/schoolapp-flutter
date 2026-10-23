import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';

export 'package:school_app_flutter/core/components/controls/collection_view_mode.dart';

/// Premier chargement, prêt, ou panne de lecture de la base locale.
///
/// Comme le fichier du personnel, un fichier jamais descendu n'est **pas** une
/// erreur : l'écran s'ouvre sur ce que la tablette connaît et le dit par un
/// bandeau.
enum HrPersonnelStatus { loading, ready, failure }

/// L'état d'un écran RH · Personnel — le Tableau de bord ou le Fichier, chacun
/// sa propre instance et donc ses propres filtres.
class HrPersonnelState extends Equatable {
  final HrPersonnelStatus status;
  final StaffFileSnapshot snapshot;
  final HrRosterQuery query;
  final CollectionViewMode viewMode;

  /// Le jour, `YYYY-MM-DD` : contrat en vigueur et ancienneté s'y lisent.
  final String today;
  final Failure? failure;

  const HrPersonnelState({
    required this.status,
    required this.snapshot,
    required this.query,
    required this.viewMode,
    required this.today,
    this.failure,
  });

  factory HrPersonnelState.initial({required String today}) => HrPersonnelState(
    status: HrPersonnelStatus.loading,
    snapshot: StaffFileSnapshot.empty,
    query: HrRosterQuery.none,
    viewMode: CollectionViewMode.grid,
    today: today,
  );

  HrPersonnelState copyWith({
    HrPersonnelStatus? status,
    StaffFileSnapshot? snapshot,
    HrRosterQuery? query,
    CollectionViewMode? viewMode,
    String? today,
    Failure? failure,
    bool clearFailure = false,
  }) => HrPersonnelState(
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
