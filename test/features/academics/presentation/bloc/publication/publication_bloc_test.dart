import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_publication.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/publication_context.dart';
import 'package:school_app_flutter/features/academics/domain/usecases/sujet/publication_usecases.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/publication/publication_state.dart';

class _MockContext extends Mock implements GetPublicationContextUseCase {}

class _MockPublish extends Mock implements PublishEvaluationUseCase {}

class _MockWithdraw extends Mock implements WithdrawPublicationUseCase {}

void main() {
  late _MockContext getContext;
  late _MockPublish publish;
  late _MockWithdraw withdraw;

  final etat = PublicationEtat(publishedAt: DateTime.utc(2026, 10, 6));

  setUp(() {
    getContext = _MockContext();
    publish = _MockPublish();
    withdraw = _MockWithdraw();
  });

  PublicationBloc build() => PublicationBloc(
    getPublicationContextUseCase: getContext,
    publishEvaluationUseCase: publish,
    withdrawPublicationUseCase: withdraw,
  );

  blocTest<PublicationBloc, PublicationState>(
    'charge le contexte',
    setUp: () => when(() => getContext('ev-1')).thenAnswer(
      (_) async => const Right(PublicationContext(notesPending: true)),
    ),
    build: build,
    act: (bloc) => bloc.add(const PublicationContextRequested('ev-1')),
    expect: () => [
      const PublicationState(
        context: PublicationContext(notesPending: true),
        loaded: true,
      ),
    ],
  );

  blocTest<PublicationBloc, PublicationState>(
    'publier : en vol, publié, puis issue consommée',
    setUp: () => when(
      () => publish('ev-1', PublicationKind.notes),
    ).thenAnswer((_) async => Right(etat)),
    build: build,
    act: (bloc) => bloc.add(
      const PublicationPublishRequested('ev-1', PublicationKind.notes),
    ),
    expect: () => [
      const PublicationState(inFlight: PublicationKind.notes),
      PublicationState(
        context: PublicationContext(
          publications: EvaluationPublications(notes: etat),
        ),
        outcome: PublicationOutcome.published,
        outcomeKind: PublicationKind.notes,
      ),
      PublicationState(
        context: PublicationContext(
          publications: EvaluationPublications(notes: etat),
        ),
        outcomeKind: PublicationKind.notes,
      ),
    ],
  );

  test(
    'un second appui pendant le vol est ignoré (un seul WhatsApp)',
    () async {
      final completer = Completer<Either<Failure, PublicationEtat>>();
      when(
        () => publish('ev-1', PublicationKind.notes),
      ).thenAnswer((_) => completer.future);
      final bloc = build();

      bloc
        ..add(const PublicationPublishRequested('ev-1', PublicationKind.notes))
        ..add(const PublicationPublishRequested('ev-1', PublicationKind.notes));
      await Future<void>.delayed(Duration.zero);
      completer.complete(Right(etat));
      await bloc.close();

      verify(() => publish('ev-1', PublicationKind.notes)).called(1);
    },
  );

  blocTest<PublicationBloc, PublicationState>(
    'un refus garde « non publié » et porte son Failure',
    setUp: () =>
        when(() => publish('ev-1', PublicationKind.corrige)).thenAnswer(
          (_) async => const Left(PublicationRefusedFailure('SUJET_EMPTY')),
        ),
    build: build,
    act: (bloc) => bloc.add(
      const PublicationPublishRequested('ev-1', PublicationKind.corrige),
    ),
    skip: 1,
    expect: () => [
      const PublicationState(
        outcome: PublicationOutcome.failed,
        outcomeKind: PublicationKind.corrige,
        failure: PublicationRefusedFailure('SUJET_EMPTY'),
      ),
      const PublicationState(
        outcomeKind: PublicationKind.corrige,
        failure: PublicationRefusedFailure('SUJET_EMPTY'),
      ),
    ],
  );
}
