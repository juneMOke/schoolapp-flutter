import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract_period.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_document.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_member.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_dossier.dart';

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
  final StaffSyncState sync;

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
  static StaffSyncState worstOf(
    StaffSyncState member,
    Iterable<StaffDocument> documents,
  ) {
    var worst = member;
    for (final document in documents) {
      if (_rank(document.syncState) > _rank(worst)) worst = document.syncState;
    }
    return worst;
  }

  static int _rank(StaffSyncState state) => switch (state) {
    StaffSyncState.failed => 2,
    StaffSyncState.pending => 1,
    StaffSyncState.synced => 0,
  };

  @override
  List<Object?> get props => [member, current, dossier, sync];
}
