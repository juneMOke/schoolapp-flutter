import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/documents/domain/entities/ticket_print_job.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_queue_use_cases.dart';

/// La page « Tickets à imprimer » : la file, et ce que le caissier y coche
/// (continuité des tickets RC, lot D).
///
/// L'impression elle-même n'est pas ici : elle demande l'imprimante à
/// l'écran, donc un `BuildContext`. La page la mène, puis relit la file.
class TicketPrintQueueCubit extends Cubit<TicketPrintQueueState> {
  final ListPendingTicketJobsUseCase _list;
  final RetryTicketReceiptUseCase _retry;

  TicketPrintQueueCubit(this._list, this._retry)
    : super(const TicketPrintQueueState());

  /// Relit la file. La sélection survit, réduite aux tickets encore prêts :
  /// un ticket imprimé ou devenu caduc ne reste pas coché en silence.
  Future<void> load() async {
    if (state.jobs.isEmpty) {
      emit(state.copyWith(phase: TicketPrintQueuePhase.loading));
    }
    final result = await _list();
    if (isClosed) return;
    result.fold(
      (_) => emit(state.copyWith(phase: TicketPrintQueuePhase.failure)),
      (jobs) {
        final ready = {
          for (final job in jobs)
            if (job.isReady) job.id,
        };
        emit(
          state.copyWith(
            phase: TicketPrintQueuePhase.loaded,
            jobs: jobs,
            selected: state.selected.intersection(ready),
          ),
        );
      },
    );
  }

  void toggle(String jobId, bool selected) {
    final job = state.jobs.where((j) => j.id == jobId).firstOrNull;
    if (job == null || !job.isReady) return;
    final next = {...state.selected};
    selected ? next.add(jobId) : next.remove(jobId);
    emit(state.copyWith(selected: next));
  }

  void toggleAll(bool selected) => emit(
    state.copyWith(
      selected: selected ? {for (final job in state.ready) job.id} : const {},
    ),
  );

  /// « Relancer » le reçu d'un ticket qui l'attend, puis relire la file : le
  /// ticket devient prêt si le reçu est revenu, reste en attente sinon.
  Future<void> retryReceipt(TicketPrintJob job) async {
    if (state.retrying.contains(job.id)) return;
    emit(state.copyWith(retrying: {...state.retrying, job.id}));
    try {
      await _retry(job);
      if (isClosed) return;
      await load();
    } finally {
      if (!isClosed) {
        emit(state.copyWith(retrying: {...state.retrying}..remove(job.id)));
      }
    }
  }

  void printingChanged(bool printing) =>
      emit(state.copyWith(printing: printing));
}

enum TicketPrintQueuePhase { loading, loaded, failure }

class TicketPrintQueueState extends Equatable {
  final TicketPrintQueuePhase phase;
  final List<TicketPrintJob> jobs;
  final Set<String> selected;

  /// Un lot est en cours d'envoi : la sélection et le bouton sont gelés.
  final bool printing;

  /// Les tickets dont le reçu est en train d'être redemandé.
  final Set<String> retrying;

  const TicketPrintQueueState({
    this.phase = TicketPrintQueuePhase.loading,
    this.jobs = const [],
    this.selected = const {},
    this.printing = false,
    this.retrying = const {},
  });

  List<TicketPrintJob> get ready => [
    for (final job in jobs)
      if (job.isReady) job,
  ];

  List<TicketPrintJob> get awaiting => [
    for (final job in jobs)
      if (!job.isReady) job,
  ];

  /// Les tickets cochés, dans l'ordre de la file — celui des numéros.
  List<TicketPrintJob> get selectedJobs => [
    for (final job in ready)
      if (selected.contains(job.id)) job,
  ];

  bool get allReadySelected =>
      ready.isNotEmpty && selected.length == ready.length;

  TicketPrintQueueState copyWith({
    TicketPrintQueuePhase? phase,
    List<TicketPrintJob>? jobs,
    Set<String>? selected,
    bool? printing,
    Set<String>? retrying,
  }) => TicketPrintQueueState(
    phase: phase ?? this.phase,
    jobs: jobs ?? this.jobs,
    selected: selected ?? this.selected,
    printing: printing ?? this.printing,
    retrying: retrying ?? this.retrying,
  );

  @override
  List<Object?> get props => [phase, jobs, selected, printing, retrying];
}
