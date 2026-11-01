import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_scope.dart';
import 'package:school_app_flutter/features/cotes/domain/repositories/cotes_repository.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_event.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/resultats/presentation/bloc/resultats_error_type.dart';

import 'fake_cotes_repository.dart';

CoteCell _server(String col, {double? cote, double? calculee}) =>
    CoteCell(key: demoKey(col), serverCote: cote, calculee: calculee);

void main() {
  late FakeCotesRepository repository;
  late int written;

  setUp(() {
    repository = FakeCotesRepository();
    written = 0;
  });

  CoteSaisieBloc build() =>
      CoteSaisieBloc(repository, onCellWritten: () => written++);

  Future<CoteSaisieReady> opened(CoteSaisieBloc bloc) async {
    bloc.add(const CoteSaisieOpened('c1'));
    return await bloc.stream.firstWhere((s) => s is CoteSaisieReady)
        as CoteSaisieReady;
  }

  Future<CoteSaisieReady> settle(CoteSaisieBloc bloc) async {
    await pumpEventQueue();
    return bloc.state as CoteSaisieReady;
  }

  group('ouverture', () {
    blocTest<CoteSaisieBloc, CoteSaisieState>(
      'chargement → prêt',
      build: build,
      act: (bloc) => bloc.add(const CoteSaisieOpened('c1')),
      expect: () => [isA<CoteSaisieLoading>(), isA<CoteSaisieReady>()],
    );

    test(
      'ouvre sur le groupe en cours et le premier élève alphabétique',
      () async {
        final bloc = build();
        final ready = await opened(bloc);

        expect(ready.scope.cibleId, 'S1');
        expect(ready.columns.map((c) => c.id), ['P1', 'P2', 'S1']);
        expect(ready.eleves.first.studentId, 'e1');
        expect(ready.currentId, 'e1');
        await bloc.close();
      },
    );

    test('la portée et l\'élève de l\'adresse sont repris', () async {
      final bloc = build();
      bloc.add(
        const CoteSaisieOpened(
          'c1',
          scope: CoteScope(portee: CotePortee.colonne, cibleId: 'P2'),
          eleveId: 'e2',
        ),
      );
      final ready =
          await bloc.stream.firstWhere((s) => s is CoteSaisieReady)
              as CoteSaisieReady;

      expect(ready.columns.single.id, 'P2');
      expect(ready.currentId, 'e2');
      await bloc.close();
    });

    test(
      'une portée et un élève inconnus retombent sur l\'ouverture',
      () async {
        final bloc = build();
        bloc.add(
          const CoteSaisieOpened(
            'c1',
            scope: CoteScope(portee: CotePortee.colonne, cibleId: 'P9'),
            eleveId: 'e9',
          ),
        );
        final ready =
            await bloc.stream.firstWhere((s) => s is CoteSaisieReady)
                as CoteSaisieReady;

        expect(ready.scope.portee, CotePortee.groupe);
        expect(ready.currentId, 'e1');
        await bloc.close();
      },
    );

    blocTest<CoteSaisieBloc, CoteSaisieState>(
      'classe sans élève → vide',
      build: () {
        repository = FakeCotesRepository(
          classe: const CoteClasse(
            classroomId: 'c1',
            decoupage: Decoupage.semestre,
            periodes: [],
            rubriques: [],
            eleves: [],
          ),
        );
        return build();
      },
      act: (bloc) => bloc.add(const CoteSaisieOpened('c1')),
      expect: () => [
        isA<CoteSaisieLoading>(),
        const CoteSaisieEmpty(CoteEmptyReason.noStudents),
      ],
    );

    blocTest<CoteSaisieBloc, CoteSaisieState>(
      'classe sans barème (422 GRID_NOT_ASSIGNED) → aucun cours',
      build: () {
        repository.loadResult = const Left(
          ApiValidationFailure(
            code: ApiErrorCode.validation,
            detailCode: 'GRID_NOT_ASSIGNED',
          ),
        );
        return build();
      },
      act: (bloc) => bloc.add(const CoteSaisieOpened('c1')),
      expect: () => [
        isA<CoteSaisieLoading>(),
        const CoteSaisieEmpty(CoteEmptyReason.noCourses),
      ],
    );

    blocTest<CoteSaisieBloc, CoteSaisieState>(
      '403 → refus d\'accès',
      build: () {
        repository.loadResult = const Left(UnauthorizedFailure());
        return build();
      },
      act: (bloc) => bloc.add(const CoteSaisieOpened('c1')),
      expect: () => [
        isA<CoteSaisieLoading>(),
        const CoteSaisieFailure(ResultatsErrorType.forbidden),
      ],
    );

    test('réessayer relance la dernière ouverture', () async {
      repository.loadResult = const Left(NetworkFailure());
      final bloc = build();
      bloc.add(const CoteSaisieOpened('c1'));
      await bloc.stream.firstWhere((s) => s is CoteSaisieFailure);
      repository.loadResult = const Right(
        CoteSnapshot(classe: demoClasse, cells: [], fromCache: true),
      );

      bloc.add(const CoteSaisieRetried());
      final ready =
          await bloc.stream.firstWhere((s) => s is CoteSaisieReady)
              as CoteSaisieReady;

      expect(ready.fromCache, isTrue);
      await bloc.close();
    });
  });

  group('frappe', () {
    test('une note valide met à jour calcul, rang et progression', () async {
      final bloc = build();
      await opened(bloc);

      bloc.add(CoteCellEdited(demoKey('P1'), '18'));
      final ready = await settle(bloc);

      expect(ready.current.total, 1800);
      expect(ready.ranking.rangs, {'e1': 1});
      expect(ready.progress.filled, 1);
      expect(repository.saved.single.$2, 18);
      expect(written, 1);
      await bloc.close();
    });

    test('virgule acceptée', () async {
      final bloc = build();
      await opened(bloc);

      bloc.add(CoteCellEdited(demoKey('P1'), '12,5'));
      await settle(bloc);

      expect(repository.saved.single.$2, 12.5);
      await bloc.close();
    });

    test('hors barème : montrée, exclue, jamais envoyée', () async {
      final bloc = build();
      await opened(bloc);

      bloc.add(CoteCellEdited(demoKey('P1'), '24'));
      final ready = await settle(bloc);

      expect(ready.current.invalid, 1);
      expect(ready.current.total, 0);
      expect(repository.saved, isEmpty);
      expect(repository.invalids.single.$2, '24');
      expect(written, 0);
      await bloc.close();
    });

    test('corriger une frappe hors barème l\'efface', () async {
      final bloc = build();
      await opened(bloc);
      bloc.add(CoteCellEdited(demoKey('P1'), '24'));
      bloc.add(CoteCellEdited(demoKey('P1'), '14'));
      final ready = await settle(bloc);

      expect(ready.current.invalid, 0);
      expect(ready.current.total, 1400);
      await bloc.close();
    });

    test('traverser une valeur calculée ne crée pas de cote', () async {
      repository = FakeCotesRepository(cells: [_server('P1', calculee: 13.25)]);
      final bloc = build();
      await opened(bloc);

      bloc.add(CoteCellEdited(demoKey('P1'), '13,25'));
      await settle(bloc);

      expect(repository.saved, isEmpty);
      expect(written, 0);
      await bloc.close();
    });

    test('remplacer une valeur calculée crée une cote', () async {
      repository = FakeCotesRepository(cells: [_server('P1', calculee: 13.25)]);
      final bloc = build();
      await opened(bloc);

      bloc.add(CoteCellEdited(demoKey('P1'), '15'));
      await settle(bloc);

      expect(repository.saved.single.$2, 15);
      await bloc.close();
    });

    test('vider une cote revient au calcul tout de suite', () async {
      repository = FakeCotesRepository(
        cells: [_server('P1', cote: 15, calculee: 13.25)],
      );
      final bloc = build();
      await opened(bloc);

      bloc.add(CoteCellEdited(demoKey('P1'), ''));
      final ready = await settle(bloc);

      expect(repository.saved.single.$2, isNull);
      final cell = ready.cells.cell('e1', 'fr', 'P1')!;
      expect(cell.displayedValue, 13.25);
      expect(cell.isCalculated, isTrue);
      expect(ready.current.total, 1325);
      await bloc.close();
    });

    test('vider une valeur seulement calculée ne fait rien', () async {
      repository = FakeCotesRepository(cells: [_server('P1', calculee: 13.25)]);
      final bloc = build();
      await opened(bloc);

      bloc.add(CoteCellEdited(demoKey('P1'), ''));
      await settle(bloc);

      expect(repository.saved, isEmpty);
      await bloc.close();
    });

    test('une colonne verrouillée n\'écrit pas', () async {
      final bloc = build();
      await opened(bloc);

      bloc.add(CoteCellEdited(demoKey('P3'), '10'));
      await settle(bloc);

      expect(repository.saved, isEmpty);
      await bloc.close();
    });

    test('un cours sans examen n\'écrit pas d\'examen', () async {
      final bloc = build();
      await opened(bloc);

      bloc.add(CoteCellEdited(demoKey('S1', cours: 'eps'), '10'));
      await settle(bloc);

      expect(repository.saved, isEmpty);
      await bloc.close();
    });

    test('les frappes s\'écrivent dans l\'ordre', () async {
      final bloc = build();
      await opened(bloc);

      for (final raw in ['1', '14', '14,', '14,5']) {
        bloc.add(CoteCellEdited(demoKey('P1'), raw));
      }
      await settle(bloc);

      expect(repository.saved.map((s) => s.$2), [1, 14, 14.5]);
      await bloc.close();
    });

    test('une écriture ratée se signale sans détruire la grille', () async {
      repository.failWrites = true;
      final bloc = build();
      await opened(bloc);

      bloc.add(CoteCellEdited(demoKey('P1'), '14'));
      final ready = await settle(bloc);

      expect(ready.storageFailed, isTrue);
      expect(written, 0);
      await bloc.close();
    });
  });

  group('navigation', () {
    test('changer de portée recalcule sans recharger', () async {
      final bloc = build();
      await opened(bloc);

      bloc.add(const CoteScopeChanged(CoteScope(portee: CotePortee.annee)));
      final ready = await settle(bloc);

      expect(ready.columns, hasLength(8));
      await bloc.close();
    });

    test('élève suivant, puis arrêt à l\'extrémité', () async {
      final bloc = build();
      await opened(bloc);

      bloc.add(const CoteStudentStepped(1));
      bloc.add(const CoteStudentStepped(1));
      final ready = await settle(bloc);

      expect(ready.currentId, 'e2');
      expect(ready.hasNext, isFalse);
      await bloc.close();
    });

    test('changer de classe revient à l\'invite', () async {
      final bloc = build();
      await opened(bloc);

      bloc.add(const CoteSaisieClosed());
      await pumpEventQueue();

      expect(bloc.state, isA<CoteSaisieIdle>());
      await bloc.close();
    });
  });

  group('après un envoi', () {
    test('une cellule dépassée est remplacée et signalée', () async {
      final bloc = build();
      await opened(bloc);
      repository.cells = [_server('P1', cote: 17)];
      repository.superseded = [demoKey('P1')];

      bloc.add(const CoteCellsRefreshed());
      final ready = await settle(bloc);

      expect(ready.current.total, 1700);
      expect(ready.changedKeys, {demoKey('P1')});
      expect(ready.changedCount, 1);
      expect(ready.changedNotice, 1);
      await bloc.close();
    });

    test('le surlignage s\'éteint au bout de 2 s', () async {
      final bloc = build();
      await opened(bloc);
      repository.superseded = [demoKey('P1')];
      bloc.add(const CoteCellsRefreshed());
      expect((await settle(bloc)).changedKeys, isNotEmpty);

      await Future<void>.delayed(
        AppMotion.changedCellHighlight + const Duration(milliseconds: 100),
      );

      expect((await settle(bloc)).changedKeys, isEmpty);
      await bloc.close();
    });

    test('une cote refusée à l\'abandon revient à la lecture', () async {
      repository = FakeCotesRepository(
        cells: [
          CoteCell(
            key: demoKey('P1'),
            hasDraft: true,
            draftValue: 15,
            syncState: SyncState.syncError,
            rejectionReason: 'PERIODE_CLOSE',
          ),
        ],
      );
      final bloc = build();
      await opened(bloc);
      repository.cells = const [];

      bloc.add(CoteRejectedDiscarded(demoKey('P1')));
      final ready = await settle(bloc);

      expect(repository.discarded, [demoKey('P1')]);
      expect(ready.current.invalid, 0);
      await bloc.close();
    });
  });
}
