import 'package:dartz/dartz.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_cell.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/repositories/cotes_repository.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';

/// Un dépôt en mémoire, qui garde la trace de ce qu'on lui demande.
class FakeCotesRepository implements CotesRepository {
  Either<Failure, CoteSnapshot> loadResult;
  List<CoteCell> cells;
  List<CoteCellKey> superseded = [];
  final saved = <(CoteCellKey, double?)>[];
  final invalids = <(CoteCellKey, String)>[];
  final clearedInvalid = <CoteCellKey>[];
  final discarded = <CoteCellKey>[];
  CoteFlushOutcome flushOutcome = CoteFlushOutcome.done;
  int pending = 0;
  int flushes = 0;

  /// Le nombre de cotes écrites au moment de chaque envoi : ce que la file
  /// portait quand elle est partie.
  final savedAtFlush = <int>[];
  int retries = 0;
  bool failWrites = false;
  final listeners = <void Function()>[];

  FakeCotesRepository({CoteClasse classe = demoClasse, this.cells = const []})
    : loadResult = Right(
        CoteSnapshot(classe: classe, cells: cells, fromCache: false),
      );

  Either<Failure, Unit> _write() =>
      failWrites ? const Left(StorageFailure('disque')) : const Right(unit);

  @override
  Future<Either<Failure, CoteSnapshot>> load(String classroomId) async =>
      loadResult;

  @override
  Future<Either<Failure, Unit>> saveValue({
    required String classroomId,
    required CoteCellKey key,
    required double? value,
  }) async {
    saved.add((key, value));
    return _write();
  }

  @override
  Future<Either<Failure, Unit>> saveInvalid({
    required String classroomId,
    required CoteCellKey key,
    required String raw,
  }) async {
    invalids.add((key, raw));
    return _write();
  }

  @override
  Future<Either<Failure, Unit>> clearInvalid(CoteCellKey key) async {
    clearedInvalid.add(key);
    return _write();
  }

  @override
  Future<Either<Failure, Unit>> discardRejected(CoteCellKey key) async {
    discarded.add(key);
    return _write();
  }

  @override
  Future<Either<Failure, List<CoteCell>>> readCells(String classroomId) async =>
      Right(cells);

  @override
  Future<Either<Failure, List<CoteCellKey>>> takeSuperseded(
    String classroomId,
  ) async {
    final taken = superseded;
    superseded = [];
    return Right(taken);
  }

  @override
  Future<int> pendingCount(String classroomId) async => pending;

  @override
  Future<CoteFlushOutcome> flush(String classroomId) async {
    flushes++;
    savedAtFlush.add(saved.length);
    return flushOutcome;
  }

  @override
  Future<void> retry(String classroomId) async => retries++;

  @override
  void Function() addFlushListener(void Function() listener) {
    listeners.add(listener);
    return () => listeners.remove(listener);
  }

  void endFlush() {
    for (final listener in List.of(listeners)) {
      listener();
    }
  }
}

const demoFr = CoteCours(
  coursId: 'fr',
  branche: 'Français',
  maxJournalier: 20,
  maxExamen: 40,
);
const demoEps = CoteCours(
  coursId: 'eps',
  branche: 'Éducation physique',
  maxJournalier: 10,
  maxExamen: 0,
);

const demoClasse = CoteClasse(
  classroomId: 'c1',
  decoupage: Decoupage.semestre,
  periodes: [
    CotePeriode(
      id: 'S1',
      ordre: 1,
      libelle: 'Semestre 1',
      courant: true,
      locked: false,
      sousPeriodes: [
        CoteSousPeriode(id: 'P1', ordre: 1, locked: false),
        CoteSousPeriode(id: 'P2', ordre: 2, locked: false),
      ],
    ),
    CotePeriode(
      id: 'S2',
      ordre: 2,
      libelle: 'Semestre 2',
      courant: false,
      locked: true,
      sousPeriodes: [
        CoteSousPeriode(id: 'P3', ordre: 1, locked: true),
        CoteSousPeriode(id: 'P4', ordre: 2, locked: false),
      ],
    ),
  ],
  rubriques: [
    CoteRubrique(
      id: 'r1',
      label: 'Domaine des Langues',
      produitSousTotal: true,
      cours: [demoFr],
    ),
    CoteRubrique(
      id: 'r2',
      label: 'Développement personnel',
      produitSousTotal: true,
      cours: [demoEps],
    ),
  ],
  eleves: [
    CoteEleve(studentId: 'e2', lastName: 'Tshala', firstName: 'Sarah'),
    CoteEleve(
      studentId: 'e1',
      lastName: 'Mbaya',
      middleName: 'Numbi',
      firstName: 'Emmanuel',
    ),
  ],
);

CoteCellKey demoKey(String col, {String student = 'e1', String cours = 'fr'}) =>
    CoteCellKey(
      studentId: student,
      coursId: cours,
      colonneId: col,
      examen: col.startsWith('S'),
    );
