import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_contract.dart';

/// L'issue d'un geste de contrat.
enum StaffContractOutcome { saved, failed }

/// Les périodes d'un agent avec leurs montants, et l'issue du dernier geste.
class StaffContractsState extends Equatable {
  /// Vide sans `hr.pay.read` : la tablette n'en a reçu aucune.
  final List<StaffContract> contracts;

  /// Un geste est en cours d'écriture : les boutons se taisent.
  final bool writing;

  /// L'issue du dernier geste, et son rang : deux issues identiques de suite
  /// s'annoncent chacune.
  final StaffContractOutcome? outcome;
  final int outcomeSeq;
  final Failure? failure;

  const StaffContractsState({
    this.contracts = const [],
    this.writing = false,
    this.outcome,
    this.outcomeSeq = 0,
    this.failure,
  });

  /// Les périodes par identifiant, pour les poser sur la frise.
  Map<String, StaffContract> get byId => {
    for (final contract in contracts) contract.id: contract,
  };

  StaffContractsState copyWith({
    List<StaffContract>? contracts,
    bool? writing,
    StaffContractOutcome? outcome,
    Failure? failure,
  }) => StaffContractsState(
    contracts: contracts ?? this.contracts,
    writing: writing ?? this.writing,
    outcome: outcome ?? this.outcome,
    outcomeSeq: outcome == null ? outcomeSeq : outcomeSeq + 1,
    failure: outcome == null ? this.failure : failure,
  );

  @override
  List<Object?> get props => [contracts, writing, outcome, outcomeSeq, failure];
}
