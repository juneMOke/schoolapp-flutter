import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/cash_register.dart';
import 'package:school_app_flutter/features/treasury/domain/repositories/cash_registers_repository.dart';
import 'package:school_app_flutter/features/treasury/presentation/bloc/cash_registers_cubit.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/registers/registers_screen.dart';

import '../../../../test_helpers/reference_formats.dart';
import '../../treasury_fixtures.dart';

class _MockRepository extends Mock implements CashRegistersRepository {}

/// Le jour de la démo : 22 octobre 2026, 10 h à Kinshasa.
DateTime _now() => DateTime.utc(2026, 10, 22, 9);

Future<void> _pump(
  WidgetTester tester, {
  required Either<Failure, List<RegisterConfig>> list,
  bool promoter = true,
  void Function()? onCreate,
  ValueChanged<RegisterConfig>? onAdjust,
}) async {
  final repo = _MockRepository();
  when(() => repo.list()).thenAnswer((_) async => list);
  await tester.pumpWidget(
    treasuryHost(
      BlocProvider(
        create: (_) => CashRegistersCubit(repo)..load(),
        child: RegistersScreen(
          now: _now,
          onCreate: promoter ? (onCreate ?? () {}) : null,
          onAdjust: promoter ? (onAdjust ?? (_) {}) : null,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testAtReferenceFormats('deux caisses, dont une clôturée avec écart', (
    tester,
    _,
  ) async {
    await _pump(
      tester,
      list: Right([
        usdConfig,
        configOf(
          cdfRegister,
          balanceInCents: 344500000,
          todayClosure: closedWithGap,
        ),
      ]),
    );
    expect(find.text('Configuration des caisses'), findsOneWidget);
    expect(find.text('4 820,00 \$'), findsOneWidget);
  });

  testWidgets('les montants s écrivent exacts, CDF sans décimales', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 900));
    await _pump(tester, list: Right([usdConfig, cdfConfig]));
    expect(find.text('3 450 000 FC'), findsOneWidget);
    // Montant d'ouverture de la caisse CDF : 75 000 000 centimes.
    expect(find.text('750 000 FC'), findsOneWidget);
  });

  testWidgets('les deux caisses existent : plus de « Nouvelle caisse »', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 900));
    await _pump(tester, list: Right([usdConfig, cdfConfig]));
    expect(find.text('Nouvelle caisse'), findsNothing);
  });

  testWidgets('une devise sans caisse : bouton d en-tête ET tuile « + »', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 900));
    var opened = 0;
    await _pump(tester, list: Right([usdConfig]), onCreate: () => opened++);
    expect(find.text('Nouvelle caisse'), findsNWidgets(2));
    await tester.tap(find.text('Nouvelle caisse').last);
    expect(opened, 1);
  });

  testWidgets('clôturée aujourd hui : l encadré remplace le bouton Ajuster', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 900));
    await _pump(
      tester,
      list: Right([
        configOf(
          cdfRegister,
          balanceInCents: 344500000,
          todayClosure: closedWithGap,
        ),
      ]),
    );
    expect(find.text('Ajuster le montant détenu'), findsNothing);
    expect(
      find.text('Clôturée aujourd\'hui : ajustement possible demain'),
      findsOneWidget,
    );
    // La sous-ligne lit l'heure de l'école et l'écart signé.
    expect(
      find.text('déclaré à la clôture de 17:45 · écart -5 000 FC'),
      findsOneWidget,
    );
  });

  testWidgets(
    'hors promoteur : aucun geste, l encadré « Consultation seule »',
    (tester) async {
      setTestWindow(tester, const Size(1280, 900));
      await _pump(tester, list: Right([usdConfig]), promoter: false);
      expect(find.text('Ajuster le montant détenu'), findsNothing);
      expect(find.text('Nouvelle caisse'), findsNothing);
      expect(
        find.textContaining('Consultation seule : seul le promoteur'),
        findsOneWidget,
      );
    },
  );

  testWidgets('aucune caisse : l état vide propose de créer', (tester) async {
    setTestWindow(tester, const Size(1280, 900));
    await _pump(tester, list: const Right([]));
    expect(find.text('Aucune caisse'), findsOneWidget);
    expect(find.text('Créer une caisse'), findsOneWidget);
  });

  testWidgets('403 : jamais « Réessayer »', (tester) async {
    setTestWindow(tester, const Size(1280, 900));
    await _pump(tester, list: const Left(UnauthorizedFailure()));
    expect(find.text('Accès refusé'), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('« Nouvelle » sur une caisse de moins de 7 jours seulement', (
    tester,
  ) async {
    setTestWindow(tester, const Size(1280, 900));
    await _pump(tester, list: Right([usdConfig, cdfConfig]));
    expect(find.text('Nouvelle'), findsOneWidget);
  });
}
