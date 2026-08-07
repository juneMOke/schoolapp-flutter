import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';

/// Référence minimale d'un dossier local (id + axe synchro) — résultat de la
/// **sonde au tap** RE : « existe-t-il déjà un dossier pour cet élève cette
/// année ? ». `syncState` pilote le mode d'ouverture (option b) : `DRAFT` →
/// reprise éditable ; finalisé (PENDING_SYNC / SYNC_ERROR / SYNCED) → lecture
/// seule.
class LocalDossierRef extends Equatable {
  final String enrollmentId;
  final SyncState syncState;

  const LocalDossierRef({required this.enrollmentId, required this.syncState});

  @override
  List<Object?> get props => [enrollmentId, syncState];
}
