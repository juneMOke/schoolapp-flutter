import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_dossier.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';

/// Une ligne du fichier : l'agent, son contrat du jour, son dossier et où en
/// est sa synchronisation.
class StaffFileRow extends Equatable {
  final StaffMember member;

  /// Le contrat en vigueur aujourd'hui ; `null` = contrat à poser.
  final StaffContractPeriod? current;

  /// `null` quand le compte ne voit pas les pièces : on ne mesure pas ce qu'on
  /// ne peut pas voir.
  final StaffDossier? dossier;

  /// Le pire état entre la fiche et ses pièces : échec, puis en attente, puis
  /// synchronisé.
  final RecordSyncState sync;

  const StaffFileRow({
    required this.member,
    required this.current,
    required this.dossier,
    required this.sync,
  });

  StaffContractKind? get kind => current?.kind;

  bool get isIncomplete =>
      dossier != null && dossier!.isKnown && !dossier!.isComplete;

  /// Agrège l'état d'une fiche et de ses pièces.
  static RecordSyncState worstOf(
    RecordSyncState member,
    Iterable<StaffDocument> documents,
  ) {
    var worst = member;
    for (final document in documents) {
      worst = worse(worst, document.syncState);
    }
    return worst;
  }

  /// Le pire de deux états : échec, puis en attente, puis synchronisé.
  /// Partagé par tout ce qui agrège des lignes (pièces, pointages).
  static RecordSyncState worse(RecordSyncState a, RecordSyncState b) =>
      _rank(b) > _rank(a) ? b : a;

  static int _rank(RecordSyncState state) => switch (state) {
    RecordSyncState.failed => 2,
    RecordSyncState.pending => 1,
    RecordSyncState.synced => 0,
  };

  @override
  List<Object?> get props => [member, current, dossier, sync];
}
