import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';

abstract class DisciplinaryCaseOfflineState extends Equatable {
  const DisciplinaryCaseOfflineState();

  @override
  List<Object?> get props => [];
}

class DisciplinaryOfflineInitial extends DisciplinaryCaseOfflineState {
  const DisciplinaryOfflineInitial();
}

class DisciplinaryOfflineLoading extends DisciplinaryCaseOfflineState {
  const DisciplinaryOfflineLoading();
}

class DisciplinaryOfflineCasesLoaded extends DisciplinaryCaseOfflineState {
  final List<OfflineDisciplinaryCase> cases;

  const DisciplinaryOfflineCasesLoaded(this.cases);

  @override
  List<Object?> get props => [cases];
}

/// Écriture (création ou traitement) en cours.
class DisciplinaryOfflineSaving extends DisciplinaryCaseOfflineState {
  const DisciplinaryOfflineSaving();
}

/// Cas créé localement : en attente de synchro (id client honoré, outbox CREATE
/// enfilé). État pending-sync exposé à l'UI.
class DisciplinaryOfflineCasePendingSync extends DisciplinaryCaseOfflineState {
  final OfflineDisciplinaryCase disciplinaryCase;

  const DisciplinaryOfflineCasePendingSync(this.disciplinaryCase);

  @override
  List<Object?> get props => [disciplinaryCase];
}

/// Cas traité localement (statut/sanction LWW, outbox UPDATE enfilé).
class DisciplinaryOfflineCaseUpdated extends DisciplinaryCaseOfflineState {
  const DisciplinaryOfflineCaseUpdated();
}

class DisciplinaryOfflineError extends DisciplinaryCaseOfflineState {
  final String message;

  const DisciplinaryOfflineError(this.message);

  @override
  List<Object?> get props => [message];
}
