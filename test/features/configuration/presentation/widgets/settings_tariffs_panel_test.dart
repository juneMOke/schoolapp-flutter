import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_code.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/fee_tariff.dart';
import 'package:school_app_flutter/features/configuration/domain/repositories/provisioning_repository.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_error_view.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/settings_tariffs_panel.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockRepository extends Mock implements ProvisioningRepository {}

void main() {
  late _MockRepository repository;

  setUp(() {
    repository = _MockRepository();
    when(
      () => repository.loadFeeCodes(
        forceRefresh: any(named: 'forceRefresh'),
        includeHidden: any(named: 'includeHidden'),
      ),
    ).thenAnswer((_) async => const Right(<FeeCodeOption>[]));
    getIt.registerFactory<ProvisioningRepository>(() => repository);
  });

  tearDown(() => getIt.reset());

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('fr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: SettingsTariffsPanel(
              levelId: 'level-1',
              levelName: '1ère Année Primaire',
              schoolLevelGroupId: 'group-1',
              academicYearId: 'year-1',
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    // Le panneau ne charge qu'à l'ouverture : les tarifs d'une vingtaine de
    // niveaux ne partent pas pour une ligne qu'on consulte.
    await tester.tap(find.text('1ère Année Primaire'));
    await tester.pump();
  }

  testWidgets('l\'attente est un squelette, jamais une barre de progression', (
    tester,
  ) async {
    when(
      () => repository.loadTariffs(any()),
    ).thenAnswer((_) => Completer<Either<Failure, List<FeeTariff>>>().future);

    await pump(tester);

    expect(find.byType(EteeloSkeletonBox), findsWidgets);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('un 403 ne propose RIEN à réessayer', (tester) async {
    // L'échec est rendu tel qu'il est venu. Rabattu sur un drapeau, il faisait
    // parler l'écran de réseau et proposait un « Réessayer » qu'aucun nouvel
    // appel n'aurait levé.
    when(
      () => repository.loadTariffs(any()),
    ).thenAnswer((_) async => const Left(UnauthorizedFailure()));

    await pump(tester);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.byType(ConfigurationErrorView), findsOneWidget);
    expect(find.text('Réessayer'), findsNothing);
  });

  testWidgets('une coupure réseau, elle, se réessaie', (tester) async {
    when(
      () => repository.loadTariffs(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure('coupure')));

    await pump(tester);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('les tarifs d\'une même nature tiennent sous le titre de l\'école', (
    tester,
  ) async {
    // La demande d'origine : sept tranches de minerval s'affichaient sept fois
    // de suite, chacune surmontée du même code brut « TUITION ». Elles tiennent
    // désormais sous un seul titre, celui que la direction a écrit.
    when(
      () => repository.loadFeeCodes(
        forceRefresh: any(named: 'forceRefresh'),
        includeHidden: any(named: 'includeHidden'),
      ),
    ).thenAnswer(
      (_) async => const Right(<FeeCodeOption>[
        FeeCodeOption(
          code: 'TUITION',
          label: 'Frais scolaires annuels',
          sortOrder: 0,
        ),
        FeeCodeOption(code: 'CANTEEN', label: 'Cantine', sortOrder: 1),
      ]),
    );
    when(() => repository.loadTariffs(any())).thenAnswer(
      (_) async => Right(<FeeTariff>[
        _tariff(id: 't1', feeCode: 'TUITION', label: '1ère tranche'),
        _tariff(id: 't2', feeCode: 'CANTEEN', label: 'Cantine annuelle'),
        _tariff(id: 't3', feeCode: 'TUITION', label: '2ème tranche'),
      ]),
    );

    await pump(tester);
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();

    // Le titre de l'école apparaît UNE fois, pas une par tranche...
    expect(find.text('Frais scolaires annuels'), findsOneWidget);
    // ...et le code brut ne s'affiche plus du tout : il ne disait rien que le
    // titre ne dise mieux.
    expect(find.text('TUITION'), findsNothing);
    expect(find.text('1ère tranche'), findsOneWidget);
    expect(find.text('2ème tranche'), findsOneWidget);
  });

  testWidgets(
    'un tarif sur une nature masquée garde son titre, et le sélecteur ne la propose plus',
    (tester) async {
      // Masquer n'efface pas : la ligne existante doit rester lisible sous le
      // nom que l'école lui avait donné, sinon elle retomberait sur « BOARDING ».
      when(
        () => repository.loadFeeCodes(
          forceRefresh: any(named: 'forceRefresh'),
          includeHidden: any(named: 'includeHidden'),
        ),
      ).thenAnswer(
        (_) async => const Right(<FeeCodeOption>[
          FeeCodeOption(
            code: 'BOARDING',
            label: 'Internat',
            active: false,
            sortOrder: 7,
          ),
        ]),
      );
      when(() => repository.loadTariffs(any())).thenAnswer(
        (_) async => Right(<FeeTariff>[
          _tariff(id: 't1', feeCode: 'BOARDING', label: 'Internat annuel'),
        ]),
      );

      await pump(tester);
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(find.text('Internat'), findsOneWidget);
      expect(find.text('BOARDING'), findsNothing);
    },
  );
}

FeeTariff _tariff({
  required String id,
  required String feeCode,
  required String label,
}) => FeeTariff(
  id: id,
  feeCode: feeCode,
  label: label,
  amountInCents: 25000,
  currency: 'USD',
  dueAt: null,
  schoolLevelId: 'level-1',
  schoolLevelGroupId: 'group-1',
);
