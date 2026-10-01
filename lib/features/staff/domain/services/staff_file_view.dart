import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_file_snapshot.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_contract_timeline.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_dossier.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_row.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Ce que l'écran liste montre : les lignes filtrées et les compteurs de la
/// synthèse. Calcul pur, refait à chaque changement de filtre — jamais de
/// relecture de la base pour filtrer.
class StaffFileView extends Equatable {
  /// Toutes les lignes du fichier, filtres ignorés.
  final List<StaffFileRow> all;

  /// Les lignes qui passent les filtres, dans l'ordre de l'état civil.
  final List<StaffFileRow> rows;

  /// Effectif par filtre de contrat, sur le fichier entier.
  final Map<StaffContractFilter, int> byContract;

  /// Agents dont le dossier est connu et incomplet.
  final int incomplete;

  /// Fiches et pièces écrites sur la tablette, pas encore au serveur.
  final int pending;

  /// Le compte voit-il les pièces ? Sinon, ni jauge ni filtre « incomplet ».
  final bool documentsVisible;

  const StaffFileView({
    required this.all,
    required this.rows,
    required this.byContract,
    required this.incomplete,
    required this.pending,
    required this.documentsVisible,
  });

  factory StaffFileView.build(
    StaffFileSnapshot snapshot, {
    required StaffFileQuery query,
    required String today,
    required bool documentsVisible,
  }) {
    final all = <StaffFileRow>[];
    var pending = 0;
    for (final member in snapshot.members) {
      final documents = snapshot.documentsByMember[member.id] ?? const [];
      final current = StaffContractTimeline.currentAt(member.contracts, today);
      final row = StaffFileRow(
        member: member,
        current: current,
        dossier: documentsVisible
            ? StaffDossier.of(
                kind: current?.kind,
                types: snapshot.documentTypes,
                documents: documents,
              )
            : null,
        sync: StaffFileRow.worstOf(member.syncState, documents),
      );
      all.add(row);
      if (member.syncState != RecordSyncState.synced) pending++;
      pending += documents
          .where((d) => d.syncState != RecordSyncState.synced)
          .length;
    }
    return StaffFileView(
      all: all,
      rows: [
        for (final row in all)
          if (query.accepts(row)) row,
      ],
      byContract: {
        for (final filter in StaffContractFilter.values)
          filter: all.where((row) => filter.matches(row.kind)).length,
      },
      incomplete: all.where((row) => row.isIncomplete).length,
      pending: pending,
      documentsVisible: documentsVisible,
    );
  }

  bool get isFileEmpty => all.isEmpty;

  /// Des agents existent, mais aucun ne passe les filtres.
  bool get isFilteredEmpty => all.isNotEmpty && rows.isEmpty;

  @override
  List<Object?> get props => [
    all,
    rows,
    byContract,
    incomplete,
    pending,
    documentsVisible,
  ];
}
