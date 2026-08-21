import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/domain/usecases/get_student_charges_usecase.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/refresh_ledger_before_collection_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_collect_preflight.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Cycle de rafraîchissement piloté par le test.
///
/// ⚠️ Le verrou est créé DANS [call], donc dans la zone `FakeAsync` du test —
/// et pas dans `setUp`, qui tourne dans la zone racine : un `Completer` né là
/// planifie ses continuations hors de l'horloge du test, que `pump()` ne draine
/// jamais. Le symptôme est une attente qui ne se dénoue pas, et qui ressemble
/// à s'y méprendre à un défaut du code testé.
class _GatedPreflight implements RefreshLedgerBeforeCollectionUseCase {
  Completer<void>? _gate;
  int calls = 0;

  /// Le cas « cycle déjà frais » : le TTL rend la main sans toucher au réseau.
  bool returnsAtOnce = false;

  @override
  Future<void> call({
    required String studentId,
    required String academicYearId,
  }) {
    calls++;
    if (returnsAtOnce) return Future<void>.value();
    return (_gate ??= Completer<void>()).future;
  }

  void release() => _gate?.complete();
}

class _FakeRead implements GetStudentChargesByAcademicYearUseCase {
  final Either<Failure, List<StudentCharge>> result;

  _FakeRead(this.result);

  @override
  Future<Either<Failure, List<StudentCharge>>> call(
    GetStudentChargesByAcademicYearParams params,
  ) async => result;
}

const _charge = StudentCharge(
  id: 'c-1',
  studentId: 's-1',
  academicYearId: 'y-1',
  schoolLevelId: 'lvl-1',
  schoolLevelGroupId: 'grp-1',
  feeTariffId: 'tar-1',
  feeCode: 'TUITION',
  label: 'Frais scolaires',
  expectedAmountInCents: 100000,
  amountPaidInCents: 0,
  currency: 'CDF',
  status: StudentChargeStatus.due,
);

/// M-8 — l'attente réseau a quitté les lectures pour se poser ICI, devant
/// l'acte d'argent : le « reste » composé qui s'affiche dans la modale borne la
/// saisie, et un versement du poste voisin qui n'est pas encore descendu fait
/// réencaisser. Ce qui est éprouvé ici : on attend bien AVANT d'ouvrir, la
/// barrière ne clignote pas quand il n'y a rien à attendre, et un échec ne
/// ferme jamais le guichet.
void main() {
  late _GatedPreflight preflight;
  late Either<Failure, List<StudentCharge>> readResult;
  List<StudentCharge>? outcome;
  var settled = false;

  setUp(() {
    preflight = _GatedPreflight();
    readResult = const Right([_charge]);
    outcome = null;
    settled = false;
    GetIt.instance.registerFactory<RefreshLedgerBeforeCollectionUseCase>(
      () => preflight,
    );
    GetIt.instance.registerFactory<GetStudentChargesByAcademicYearUseCase>(
      () => _FakeRead(readResult),
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget host() => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            unawaited(
              runFacturationCollectPreflight(
                context,
                studentId: 's-1',
                academicYearId: 'y-1',
              ).then((charges) {
                settled = true;
                outcome = charges;
              }),
            );
          },
          child: const Text('encaisser'),
        ),
      ),
    ),
  );

  testWidgets(
    'attend le cycle avant de rendre les créances, et le dit à l\'écran',
    (tester) async {
      await tester.pumpWidget(host());
      await tester.tap(find.text('encaisser'));
      await tester.pump();

      // Passé le délai d'apparition, l'attente est visible et rien n'est rendu.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(settled, isFalse);
      expect(preflight.calls, 1);

      preflight.release();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(settled, isTrue);
      expect(outcome, [_charge]);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets('cycle déjà frais : aucune barrière ne clignote', (tester) async {
    preflight.returnsAtOnce = true;
    await tester.pumpWidget(host());
    await tester.tap(find.text('encaisser'));
    await tester.pump();
    // Au-delà du délai d'apparition : la course était tranchée avant.
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(settled, isTrue);
    expect(outcome, [_charge]);
  });

  testWidgets(
    'relecture locale en échec : rend null — l\'appelant garde ce qui est '
    'affiché plutôt que de fermer le guichet',
    (tester) async {
      readResult = const Left(StorageFailure('base occupée'));
      preflight.returnsAtOnce = true;
      await tester.pumpWidget(host());
      await tester.tap(find.text('encaisser'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(settled, isTrue);
      expect(outcome, isNull);
    },
  );
}
