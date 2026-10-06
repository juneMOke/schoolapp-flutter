import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/copie_diffusion.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/get_copie_log_usecase.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/log_copie_diffusion_usecase.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/copie/copie_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/copie/copie_state.dart';

/// Journal des copies (spec S5). Best-effort : un journal illisible ou une
/// écriture en échec ne bloque jamais l'impression ni le partage, déjà faits.
class CopieBloc extends Bloc<CopieEvent, CopieState> {
  final GetCopieLogUseCase _getLog;
  final LogCopieDiffusionUseCase _logDiffusion;

  CopieBloc({
    required GetCopieLogUseCase getCopieLogUseCase,
    required LogCopieDiffusionUseCase logCopieDiffusionUseCase,
  }) : _getLog = getCopieLogUseCase,
       _logDiffusion = logCopieDiffusionUseCase,
       super(const CopieState()) {
    on<CopieLogRequested>(_onRequested);
    on<CopieDiffused>(_onDiffused);
  }

  Future<void> _onRequested(
    CopieLogRequested event,
    Emitter<CopieState> emit,
  ) async {
    final result = await _getLog(event.evaluationId);
    result.fold((_) {}, (log) => emit(CopieState(log: log)));
  }

  Future<void> _onDiffused(
    CopieDiffused event,
    Emitter<CopieState> emit,
  ) async {
    final result = await _logDiffusion(
      event.evaluationId,
      kind: event.kind,
      // La feuille de partage du système ne dit pas l'appli choisie.
      canal: event.kind == CopieKind.share ? CopieCanal.systeme : null,
      corrige: event.corrige,
    );
    result.fold(
      (_) {},
      (diffusion) => emit(CopieState(log: [diffusion, ...state.log])),
    );
  }
}
