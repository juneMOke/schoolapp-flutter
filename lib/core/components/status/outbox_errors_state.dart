import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/offline/outbox_entry.dart';

/// Phase de chargement de la liste des écritures en échec.
enum OutboxErrorsStatus { loading, loaded, failure }

/// État de la feuille de reprise (`SyncErrorsSheet`).
///
/// [busy] couvre une action en cours (requeue / abandon / flush) : il verrouille
/// les boutons sans masquer la liste — un rejeu d'argent ne doit jamais pouvoir
/// être déclenché deux fois par un double tap.
class OutboxErrorsState extends Equatable {
  final OutboxErrorsStatus status;
  final List<OutboxEntry> entries;
  final bool busy;

  const OutboxErrorsState({
    this.status = OutboxErrorsStatus.loading,
    this.entries = const <OutboxEntry>[],
    this.busy = false,
  });

  bool get isEmpty => status == OutboxErrorsStatus.loaded && entries.isEmpty;

  OutboxErrorsState copyWith({
    OutboxErrorsStatus? status,
    List<OutboxEntry>? entries,
    bool? busy,
  }) => OutboxErrorsState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
    busy: busy ?? this.busy,
  );

  @override
  List<Object?> get props => [status, entries, busy];
}
