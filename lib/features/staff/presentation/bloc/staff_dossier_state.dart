import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_dossier_snapshot.dart';

/// Ce qu'un geste sur une pièce a donné.
enum StaffDocumentOutcome { saved, saveFailed, openFailed }

/// Le dossier d'un agent, et l'issue du dernier geste.
class StaffDossierState extends Equatable {
  final StaffDossierSnapshot dossier;

  /// Une première lecture a abouti : avant, un dossier vide ne veut rien dire.
  final bool loaded;

  /// Un versement ou une ouverture est en cours : les boutons se taisent.
  final bool busy;

  /// L'issue du dernier geste et son rang : deux issues identiques de suite
  /// s'annoncent chacune.
  final StaffDocumentOutcome? outcome;
  final int outcomeSeq;
  final Failure? failure;

  const StaffDossierState({
    this.dossier = StaffDossierSnapshot.empty,
    this.loaded = false,
    this.busy = false,
    this.outcome,
    this.outcomeSeq = 0,
    this.failure,
  });

  StaffDossierState copyWith({
    StaffDossierSnapshot? dossier,
    bool? loaded,
    bool? busy,
    StaffDocumentOutcome? outcome,
    Failure? failure,
  }) => StaffDossierState(
    dossier: dossier ?? this.dossier,
    loaded: loaded ?? this.loaded,
    busy: busy ?? this.busy,
    outcome: outcome ?? this.outcome,
    outcomeSeq: outcome == null ? outcomeSeq : outcomeSeq + 1,
    failure: outcome == null ? this.failure : failure,
  );

  @override
  List<Object?> get props => [
    dossier,
    loaded,
    busy,
    outcome,
    outcomeSeq,
    failure,
  ];
}
