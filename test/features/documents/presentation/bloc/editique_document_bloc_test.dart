import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_account_statement_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_enrollment_attestation_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_financial_clearance_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_note_perception_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_payment_receipt_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/student_year_document_params.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_document_bloc.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_error_type.dart';

class MockEmitPaymentReceiptUseCase extends Mock
    implements EmitPaymentReceiptUseCase {}

class MockEmitAccountStatementUseCase extends Mock
    implements EmitAccountStatementUseCase {}

class MockEmitEnrollmentAttestationUseCase extends Mock
    implements EmitEnrollmentAttestationUseCase {}

class MockEmitNotePerceptionUseCase extends Mock
    implements EmitNotePerceptionUseCase {}

class MockEmitFinancialClearanceUseCase extends Mock
    implements EmitFinancialClearanceUseCase {}

final _receipt = EditiqueDocument(
  type: EditiqueDocumentType.paymentReceipt,
  bytes: Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46]),
  fileName: 'ETL-RC-2526-000212.pdf',
  documentNumber: 'ETL-RC-2526-000212',
);

/// Pièce minimale d'un type donné — les octets n'ont pas d'importance ici, seul
/// le routage du BLoC est sous test.
EditiqueDocument _documentOf(EditiqueDocumentType type) => EditiqueDocument(
  type: type,
  bytes: Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46]),
  fileName: 'ETL-${type.code}-2526-000001.pdf',
  documentNumber: 'ETL-${type.code}-2526-000001',
);

void main() {
  late MockEmitPaymentReceiptUseCase useCase;

  setUpAll(() {
    registerFallbackValue(const EmitPaymentReceiptParams(paymentId: 'x'));
    registerFallbackValue(
      const StudentYearDocumentParams(studentId: 'x', academicYearId: 'y'),
    );
    registerFallbackValue(
      const EmitEnrollmentAttestationParams(enrollmentId: 'x'),
    );
  });

  late MockEmitAccountStatementUseCase statementUseCase;
  late MockEmitEnrollmentAttestationUseCase attestationUseCase;
  late MockEmitNotePerceptionUseCase notePerceptionUseCase;
  late MockEmitFinancialClearanceUseCase clearanceUseCase;

  setUp(() {
    useCase = MockEmitPaymentReceiptUseCase();
    statementUseCase = MockEmitAccountStatementUseCase();
    attestationUseCase = MockEmitEnrollmentAttestationUseCase();
    notePerceptionUseCase = MockEmitNotePerceptionUseCase();
    clearanceUseCase = MockEmitFinancialClearanceUseCase();
  });

  EditiqueDocumentBloc build() => EditiqueDocumentBloc(
    emitEnrollmentAttestationUseCase: attestationUseCase,
    emitNotePerceptionUseCase: notePerceptionUseCase,
    emitPaymentReceiptUseCase: useCase,
    emitAccountStatementUseCase: statementUseCase,
    emitFinancialClearanceUseCase: clearanceUseCase,
  );

  blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
    'émet chargement puis succès et porte le document',
    setUp: () =>
        when(() => useCase(any())).thenAnswer((_) async => Right(_receipt)),
    build: build,
    act: (bloc) =>
        bloc.add(const EditiquePaymentReceiptRequested(paymentId: 'p-1')),
    expect: () => [
      isA<EditiqueDocumentState>()
          .having((s) => s.status, 'status', EditiqueDocumentStatus.loading)
          .having((s) => s.type, 'type', EditiqueDocumentType.paymentReceipt),
      isA<EditiqueDocumentState>()
          .having((s) => s.status, 'status', EditiqueDocumentStatus.success)
          .having((s) => s.document, 'document', _receipt),
    ],
    verify: (_) => verify(
      () => useCase(const EmitPaymentReceiptParams(paymentId: 'p-1')),
    ).called(1),
  );

  blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
    'traduit chaque Failure du socle en type d erreur',
    setUp: () => when(
      () => useCase(any()),
    ).thenAnswer((_) async => const Left(NotFoundFailure())),
    build: build,
    act: (bloc) =>
        bloc.add(const EditiquePaymentReceiptRequested(paymentId: 'p-1')),
    skip: 1,
    expect: () => [
      isA<EditiqueDocumentState>()
          .having((s) => s.status, 'status', EditiqueDocumentStatus.failure)
          .having((s) => s.errorType, 'errorType', EditiqueErrorType.notFound),
    ],
  );

  blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
    'classe une issue inconnue à part du réseau',
    setUp: () => when(
      () => useCase(any()),
    ).thenAnswer((_) async => const Left(UncertainOutcomeFailure())),
    build: build,
    act: (bloc) =>
        bloc.add(const EditiquePaymentReceiptRequested(paymentId: 'p-1')),
    skip: 1,
    expect: () => [
      isA<EditiqueDocumentState>().having(
        (s) => s.errorType,
        'errorType',
        EditiqueErrorType.uncertain,
      ),
    ],
  );

  // Sur une pièce non archivée, un second envoi brûlerait un second numéro de
  // séquence côté serveur. Le verrou est donc money-grade, pas cosmétique.
  blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
    'ignore une seconde demande tant que la première est en vol',
    setUp: () => when(() => useCase(any())).thenAnswer(
      (_) => Future.delayed(
        const Duration(milliseconds: 40),
        () => Right(_receipt),
      ),
    ),
    build: build,
    act: (bloc) => bloc
      ..add(const EditiquePaymentReceiptRequested(paymentId: 'p-1'))
      ..add(const EditiquePaymentReceiptRequested(paymentId: 'p-1')),
    wait: const Duration(milliseconds: 120),
    verify: (_) => verify(() => useCase(any())).called(1),
  );

  blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
    'purge le document précédent au rejeu',
    setUp: () {
      var call = 0;
      when(() => useCase(any())).thenAnswer((_) async {
        call++;
        return call == 1 ? Right(_receipt) : const Left(ServerFailure('boum'));
      });
    },
    build: build,
    act: (bloc) async {
      bloc.add(const EditiquePaymentReceiptRequested(paymentId: 'p-1'));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      bloc.add(const EditiquePaymentReceiptRequested(paymentId: 'p-1'));
    },
    wait: const Duration(milliseconds: 40),
    verify: (bloc) {
      expect(bloc.state.status, EditiqueDocumentStatus.failure);
      expect(bloc.state.document, isNull);
    },
  );

  group('relevé de compte', () {
    final statement = EditiqueDocument(
      type: EditiqueDocumentType.accountStatement,
      bytes: Uint8List.fromList(<int>[0x25, 0x50, 0x44, 0x46]),
      fileName: 'ETL-RL-2526-000009.pdf',
      documentNumber: 'ETL-RL-2526-000009',
    );

    blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
      'transmet élève et année, et porte le type horodaté',
      setUp: () => when(
        () => statementUseCase(any()),
      ).thenAnswer((_) async => Right(statement)),
      build: build,
      act: (bloc) => bloc.add(
        const EditiqueAccountStatementRequested(
          studentId: 's-7',
          academicYearId: 'y-9',
        ),
      ),
      expect: () => [
        isA<EditiqueDocumentState>()
            .having((s) => s.status, 'status', EditiqueDocumentStatus.loading)
            .having(
              (s) => s.type,
              'type',
              EditiqueDocumentType.accountStatement,
            ),
        isA<EditiqueDocumentState>()
            .having((s) => s.status, 'status', EditiqueDocumentStatus.success)
            .having((s) => s.document?.isReplayable, 'isReplayable', isFalse),
      ],
      verify: (_) => verify(
        () => statementUseCase(
          const StudentYearDocumentParams(
            studentId: 's-7',
            academicYearId: 'y-9',
          ),
        ),
      ).called(1),
    );

    // Le point money-grade du relevé : chaque appel brûle un numéro de
    // séquence. Deux envois rapprochés ne doivent jamais produire deux pièces.
    blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
      'ignore un second envoi tant que le premier est en vol',
      setUp: () => when(() => statementUseCase(any())).thenAnswer(
        (_) => Future.delayed(
          const Duration(milliseconds: 40),
          () => Right(statement),
        ),
      ),
      build: build,
      act: (bloc) => bloc
        ..add(
          const EditiqueAccountStatementRequested(
            studentId: 's-7',
            academicYearId: 'y-9',
          ),
        )
        ..add(
          const EditiqueAccountStatementRequested(
            studentId: 's-7',
            academicYearId: 'y-9',
          ),
        ),
      wait: const Duration(milliseconds: 120),
      verify: (_) => verify(() => statementUseCase(any())).called(1),
    );

    blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
      'un 404 « aucune créance » reste sans reprise possible',
      setUp: () => when(
        () => statementUseCase(any()),
      ).thenAnswer((_) async => const Left(NotFoundFailure())),
      build: build,
      act: (bloc) => bloc.add(
        const EditiqueAccountStatementRequested(
          studentId: 's-7',
          academicYearId: 'y-9',
        ),
      ),
      skip: 1,
      expect: () => [
        isA<EditiqueDocumentState>()
            .having((s) => s.errorType, 'errorType', EditiqueErrorType.notFound)
            .having((s) => s.canRetry, 'canRetry', isFalse),
      ],
    );
  });

  group('canRetry', () {
    test('autorise la reprise sur une pièce archivée, même issue inconnue', () {
      const state = EditiqueDocumentState(
        status: EditiqueDocumentStatus.failure,
        type: EditiqueDocumentType.paymentReceipt,
        errorType: EditiqueErrorType.uncertain,
      );
      expect(state.canRetry, isTrue);
    });

    // Le cœur de la règle : relevé et quitus consomment un numéro avant le
    // rendu du PDF, donc un rejeu après une issue inconnue crée un doublon.
    test('interdit la reprise sur une pièce horodatée à issue inconnue', () {
      for (final type in [
        EditiqueDocumentType.accountStatement,
        EditiqueDocumentType.financialClearance,
      ]) {
        final state = EditiqueDocumentState(
          status: EditiqueDocumentStatus.failure,
          type: type,
          errorType: EditiqueErrorType.uncertain,
        );
        expect(state.canRetry, isFalse, reason: type.name);
      }
    });

    // Seul l'échec réseau prouve que la requête n'est jamais partie : c'est la
    // seule reprise sûre sur une pièce dont le numéro se consomme à l'appel.
    test('autorise la reprise sur une pièce horodatée en échec réseau', () {
      const state = EditiqueDocumentState(
        status: EditiqueDocumentStatus.failure,
        type: EditiqueDocumentType.accountStatement,
        errorType: EditiqueErrorType.network,
      );
      expect(state.canRetry, isTrue);
    });

    // Un 500 arrive APRÈS que le serveur a réservé le numéro : le rendu du PDF
    // a échoué, mais la séquence est déjà avancée.
    test('interdit la reprise sur une pièce horodatée en erreur serveur', () {
      for (final errorType in [
        EditiqueErrorType.server,
        EditiqueErrorType.invalid,
        EditiqueErrorType.notFound,
      ]) {
        final state = EditiqueDocumentState(
          status: EditiqueDocumentStatus.failure,
          type: EditiqueDocumentType.financialClearance,
          errorType: errorType,
        );
        expect(state.canRetry, isFalse, reason: errorType.name);
      }
    });

    // Une pièce archivée reste rejouable quelle que soit l'erreur : le serveur
    // re-sert les mêmes octets sous le même numéro.
    test('autorise la reprise sur une pièce archivée en erreur serveur', () {
      const state = EditiqueDocumentState(
        status: EditiqueDocumentStatus.failure,
        type: EditiqueDocumentType.paymentReceipt,
        errorType: EditiqueErrorType.server,
      );
      expect(state.canRetry, isTrue);
    });

    // Type inconnu : on se rabat sur le régime le plus prudent.
    test('traite un type inconnu comme non rejouable', () {
      const state = EditiqueDocumentState(
        status: EditiqueDocumentStatus.failure,
        errorType: EditiqueErrorType.server,
      );
      expect(state.canRetry, isFalse);
    });

    test('interdit toujours la reprise sur un accès refusé', () {
      const state = EditiqueDocumentState(
        status: EditiqueDocumentStatus.failure,
        type: EditiqueDocumentType.paymentReceipt,
        errorType: EditiqueErrorType.forbidden,
      );
      expect(state.canRetry, isFalse);
    });

    test('reste faux hors état d échec', () {
      const state = EditiqueDocumentState(
        status: EditiqueDocumentStatus.loading,
        type: EditiqueDocumentType.paymentReceipt,
      );
      expect(state.canRetry, isFalse);
    });
  });

  group('les cinq pièces sont câblées', () {
    blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
      'attestation d inscription : route vers son use case et porte son type',
      setUp: () => when(() => attestationUseCase(any())).thenAnswer(
        (_) async =>
            Right(_documentOf(EditiqueDocumentType.enrollmentAttestation)),
      ),
      build: build,
      act: (bloc) => bloc.add(
        const EditiqueEnrollmentAttestationRequested(enrollmentId: 'e-1'),
      ),
      verify: (_) {
        verify(
          () => attestationUseCase(
            const EmitEnrollmentAttestationParams(enrollmentId: 'e-1'),
          ),
        ).called(1);
        verifyNever(() => useCase(any()));
      },
      expect: () => [
        isA<EditiqueDocumentState>().having(
          (s) => s.type,
          'type',
          EditiqueDocumentType.enrollmentAttestation,
        ),
        isA<EditiqueDocumentState>()
            .having((s) => s.status, 'status', EditiqueDocumentStatus.success)
            .having((s) => s.canRetry, 'canRetry', isFalse),
      ],
    );

    blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
      'note de perception : route vers son use case avec l élève et l année',
      setUp: () => when(() => notePerceptionUseCase(any())).thenAnswer(
        (_) async => Right(_documentOf(EditiqueDocumentType.notePerception)),
      ),
      build: build,
      act: (bloc) => bloc.add(
        const EditiqueNotePerceptionRequested(
          studentId: 's-1',
          academicYearId: 'y-1',
        ),
      ),
      verify: (_) => verify(
        () => notePerceptionUseCase(
          const StudentYearDocumentParams(
            studentId: 's-1',
            academicYearId: 'y-1',
          ),
        ),
      ).called(1),
      expect: () => [
        isA<EditiqueDocumentState>().having(
          (s) => s.type,
          'type',
          EditiqueDocumentType.notePerception,
        ),
        isA<EditiqueDocumentState>().having(
          (s) => s.status,
          'status',
          EditiqueDocumentStatus.success,
        ),
      ],
    );

    blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
      'quitus : route vers son use case et reste non rejouable après un 500',
      setUp: () => when(
        () => clearanceUseCase(any()),
      ).thenAnswer((_) async => const Left(ServerFailure())),
      build: build,
      act: (bloc) => bloc.add(
        const EditiqueFinancialClearanceRequested(
          studentId: 's-1',
          academicYearId: 'y-1',
        ),
      ),
      verify: (_) => verify(() => clearanceUseCase(any())).called(1),
      expect: () => [
        isA<EditiqueDocumentState>().having(
          (s) => s.type,
          'type',
          EditiqueDocumentType.financialClearance,
        ),
        // Pièce non archivée : le numéro de séquence a pu être brûlé avant
        // l'échec, donc aucune reprise n'est offerte.
        isA<EditiqueDocumentState>()
            .having((s) => s.status, 'status', EditiqueDocumentStatus.failure)
            .having((s) => s.canRetry, 'canRetry', isFalse),
      ],
    );
  });

  group('détail serveur', () {
    // Le motif décodé en couche data était jusqu'ici jeté au seuil de la
    // présentation : c'est pourtant la seule information utile ici.
    blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
      'remonte le motif renvoyé par le serveur',
      setUp: () => when(() => notePerceptionUseCase(any())).thenAnswer(
        (_) async => const Left(NotFoundFailure('Aucune charge pour l élève')),
      ),
      build: build,
      act: (bloc) => bloc.add(
        const EditiqueNotePerceptionRequested(
          studentId: 's-1',
          academicYearId: 'y-1',
        ),
      ),
      skip: 1,
      expect: () => [
        isA<EditiqueDocumentState>().having(
          (s) => s.serverDetail,
          'serverDetail',
          'Aucune charge pour l élève',
        ),
      ],
    );

    // Le message par défaut de la classe n'est pas un motif serveur : c'est une
    // constante technique en anglais que l'anatomie dit déjà mieux.
    blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
      'n expose aucun détail quand le serveur n a rien dit',
      setUp: () => when(
        () => notePerceptionUseCase(any()),
      ).thenAnswer((_) async => const Left(NotFoundFailure())),
      build: build,
      act: (bloc) => bloc.add(
        const EditiqueNotePerceptionRequested(
          studentId: 's-1',
          academicYearId: 'y-1',
        ),
      ),
      skip: 1,
      expect: () => [
        isA<EditiqueDocumentState>().having(
          (s) => s.serverDetail,
          'serverDetail',
          isNull,
        ),
      ],
    );

    // Sans réponse HTTP, il n'y a pas de corps à décoder : la pré-garde de
    // connectivité du repository ne doit pas ressortir comme un motif serveur.
    blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
      'n expose aucun détail sur un échec de transport',
      setUp: () => when(() => notePerceptionUseCase(any())).thenAnswer(
        (_) async => const Left(
          NetworkFailure(
            'Aucune connexion : le document ne peut pas être émis.',
          ),
        ),
      ),
      build: build,
      act: (bloc) => bloc.add(
        const EditiqueNotePerceptionRequested(
          studentId: 's-1',
          academicYearId: 'y-1',
        ),
      ),
      skip: 1,
      expect: () => [
        isA<EditiqueDocumentState>()
            .having((s) => s.serverDetail, 'serverDetail', isNull)
            .having((s) => s.errorType, 'errorType', EditiqueErrorType.network),
      ],
    );

    // Un détail survivant à une reprise décrirait l'échec précédent.
    blocTest<EditiqueDocumentBloc, EditiqueDocumentState>(
      'efface le détail au déclenchement suivant',
      setUp: () {
        when(
          () => notePerceptionUseCase(any()),
        ).thenAnswer((_) async => const Left(NotFoundFailure('Aucune charge')));
        when(() => attestationUseCase(any())).thenAnswer(
          (_) async =>
              Right(_documentOf(EditiqueDocumentType.enrollmentAttestation)),
        );
      },
      build: build,
      act: (bloc) async {
        bloc.add(
          const EditiqueNotePerceptionRequested(
            studentId: 's-1',
            academicYearId: 'y-1',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const EditiqueEnrollmentAttestationRequested(enrollmentId: 'e-1'),
        );
      },
      skip: 2,
      expect: () => [
        isA<EditiqueDocumentState>()
            .having((s) => s.status, 'status', EditiqueDocumentStatus.loading)
            .having((s) => s.serverDetail, 'serverDetail', isNull),
        isA<EditiqueDocumentState>().having(
          (s) => s.status,
          'status',
          EditiqueDocumentStatus.success,
        ),
      ],
    );
  });
}
