import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/publication_usecases.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_state.dart';

/// Publication aux parents (spec S6-S7). Un seul appel à la fois ; un geste
/// en vol ignore les suivants (pas de double WhatsApp sur un double appui).
class PublicationBloc extends Bloc<PublicationEvent, PublicationState> {
  final GetPublicationContextUseCase _getContext;
  final PublishEvaluationUseCase _publish;
  final WithdrawPublicationUseCase _withdraw;

  PublicationBloc({
    required GetPublicationContextUseCase getPublicationContextUseCase,
    required PublishEvaluationUseCase publishEvaluationUseCase,
    required WithdrawPublicationUseCase withdrawPublicationUseCase,
  }) : _getContext = getPublicationContextUseCase,
       _publish = publishEvaluationUseCase,
       _withdraw = withdrawPublicationUseCase,
       super(const PublicationState()) {
    on<PublicationContextRequested>(_onContext);
    on<PublicationPublishRequested>(_onPublish);
    on<PublicationWithdrawRequested>(_onWithdraw);
  }

  Future<void> _onContext(
    PublicationContextRequested event,
    Emitter<PublicationState> emit,
  ) async {
    final result = await _getContext(event.evaluationId);
    result.fold(
      (_) => emit(state.copyWith(loaded: true)),
      (context) => emit(state.copyWith(context: context, loaded: true)),
    );
  }

  Future<void> _onPublish(
    PublicationPublishRequested event,
    Emitter<PublicationState> emit,
  ) => _act(
    emit,
    event.kind,
    PublicationOutcome.published,
    () async => (await _publish(
      event.evaluationId,
      event.kind,
    )).map<PublicationEtat?>((etat) => etat),
  );

  Future<void> _onWithdraw(
    PublicationWithdrawRequested event,
    Emitter<PublicationState> emit,
  ) => _act(
    emit,
    event.kind,
    PublicationOutcome.withdrawn,
    () async => (await _withdraw(
      event.evaluationId,
      event.kind,
    )).map<PublicationEtat?>((_) => null),
  );

  /// Un geste : l'élément en vol, l'appel, puis l'état posé et l'issue
  /// rendue une fois.
  Future<void> _act(
    Emitter<PublicationState> emit,
    PublicationKind kind,
    PublicationOutcome success,
    Future<Either<Failure, PublicationEtat?>> Function() call,
  ) async {
    if (state.inFlight != null) return;
    emit(state.copyWith(inFlight: () => kind));
    final result = await call();
    result.fold(
      (failure) => emit(
        state.copyWith(
          inFlight: () => null,
          outcome: PublicationOutcome.failed,
          outcomeKind: () => kind,
          failure: () => failure,
        ),
      ),
      (etat) => emit(
        state.copyWith(
          context: state.context.withPublications(
            state.context.publications.withKind(kind, etat),
          ),
          inFlight: () => null,
          outcome: success,
          outcomeKind: () => kind,
          failure: () => null,
        ),
      ),
    );
    emit(state.copyWith(outcome: PublicationOutcome.none));
  }
}
