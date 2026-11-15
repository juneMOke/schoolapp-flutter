import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/report_signatory.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_refusal.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/report_signatories_repository.dart';
import 'package:school_app_flutter/features/treasury/domain/services/report_signatory_rules.dart';

enum ReportSignatoriesStatus { loading, ready, failure }

class ReportSignatoriesState extends Equatable {
  final ReportSignatoriesStatus status;
  final ReportSignatories? signatories;
  final Failure? failure;

  const ReportSignatoriesState({
    this.status = ReportSignatoriesStatus.loading,
    this.signatories,
    this.failure,
  });

  @override
  List<Object?> get props => [status, signatories, failure];
}

/// Trésorerie ▸ Configuration ▸ Signataires des rapports.
///
/// Un enregistrement remplace toute la liste, gardé par l'instant de la liste
/// montrée : si elle a changé entre-temps, le serveur refuse et rend la liste
/// actuelle, qui devient celle de l'écran. Rien n'est jamais rejoué.
class ReportSignatoriesCubit extends Cubit<ReportSignatoriesState> {
  final ReportSignatoriesRepository _repository;

  ReportSignatoriesCubit(this._repository)
    : super(const ReportSignatoriesState());

  Future<void> load() async {
    emit(const ReportSignatoriesState());
    final result = await _repository.fetch();
    if (isClosed) return;
    emit(
      result.fold(
        (failure) => ReportSignatoriesState(
          status: ReportSignatoriesStatus.failure,
          failure: failure,
        ),
        (signatories) => ReportSignatoriesState(
          status: ReportSignatoriesStatus.ready,
          signatories: signatories,
        ),
      ),
    );
  }

  static bool _changedUnreadable(Either<Failure, ReportSignatories> result) =>
      result.fold(
        (f) =>
            f is TreasuryRefusalFailure &&
            f.refusal == TreasuryRefusal.signatoriesChanged,
        (_) => false,
      );

  /// Relit la liste sans repasser par le squelette.
  Future<void> _refresh() async {
    final result = await _repository.fetch();
    if (isClosed) return;
    result.fold((_) {}, (signatories) {
      emit(
        ReportSignatoriesState(
          status: ReportSignatoriesStatus.ready,
          signatories: signatories,
        ),
      );
    });
  }

  /// Enregistre [list] (vide = retour aux blocs par défaut).
  Future<Either<Failure, ReportSignatories>> save(
    List<ReportSignatory> list,
  ) async {
    final result = await _repository.replace(
      expectedUpdatedAt: state.signatories?.updatedAtWire,
      signatories: ReportSignatoryRules.trimmed(list),
    );
    if (isClosed) return result;
    final current = result.fold(
      (failure) =>
          failure is SignatoriesChangedFailure ? failure.current : null,
      (saved) => saved,
    );
    if (current != null) {
      emit(
        ReportSignatoriesState(
          status: ReportSignatoriesStatus.ready,
          signatories: current,
        ),
      );
    } else if (_changedUnreadable(result)) {
      // Le refus ne dit pas quelle liste est en place : on la relit, sinon
      // chaque nouvel essai repartirait de l'instant périmé.
      await _refresh();
    }
    return result;
  }
}
