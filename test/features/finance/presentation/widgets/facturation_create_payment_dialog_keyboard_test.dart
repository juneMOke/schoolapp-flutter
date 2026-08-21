import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_state.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_dialog.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_payer_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockPaymentsBloc extends MockBloc<PaymentsEvent, PaymentsState>
    implements PaymentsBloc {}

class _MockFinanceOfflineBloc
    extends MockBloc<FinanceOfflineEvent, FinanceOfflineState>
    implements FinanceOfflineBloc {}

/// La modale d'encaissement est une modale de SAISIE : ouvrir le clavier y est
/// le geste normal. Or `Dialog` retranche la hauteur du clavier à ce qu'il offre
/// à son contenu — sur un téléphone en paysage il n'en reste qu'une douzaine de
/// dp, quand l'en-tête, la bande de total et le bouton d'encaissement en
/// réclament plus de deux cents. La disposition débordait alors de 167 dp
/// (731×411) à 218 dp (640×360).
///
/// Deux débordements distincts sont couverts ici : le vertical, provoqué par le
/// clavier, et l'horizontal du titre de la section payeur, qui lui frappait dès
/// qu'on ouvrait la modale sur un téléphone étroit — clavier ou pas.
void main() {
  late _MockPaymentsBloc payments;
  late _MockFinanceOfflineBloc offline;

  setUp(() {
    payments = _MockPaymentsBloc();
    offline = _MockFinanceOfflineBloc();
    when(() => payments.state).thenReturn(const PaymentsState());
    when(() => offline.state).thenReturn(const FinanceOfflineInitial());
  });

  StudentCharge charge(String id) => StudentCharge(
    id: id,
    studentId: 'stu-1',
    academicYearId: 'ay-1',
    schoolLevelId: 'lvl-1',
    schoolLevelGroupId: 'grp-1',
    feeTariffId: 'tar-1',
    feeCode: 'SCOLARITE',
    label: 'Scolarité $id',
    expectedAmountInCents: 150000,
    amountPaidInCents: 0,
    currency: 'USD',
    status: StudentChargeStatus.due,
  );

  Future<void> ouvrir(WidgetTester tester, Size surface) async {
    await tester.binding.setSurfaceSize(surface);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PaymentsBloc>.value(value: payments),
          BlocProvider<FinanceOfflineBloc>.value(value: offline),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FacturationCreatePaymentDialogView(
            intent: FacturationCreatePaymentIntent(
              studentId: 'stu-1',
              academicYearId: 'ay-1',
              firstName: 'Daniel',
              lastName: 'Kabongo',
              surname: 'Mwamba',
              levelName: '6e A',
              levelGroupName: 'Secondaire',
              studentCharges: [charge('1'), charge('2'), charge('3')],
            ),
            onPaymentCreated: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Le clavier tel que le framework le voit : des `viewInsets`, en pixels
  /// **physiques** (`MediaQuery` les divise par le `devicePixelRatio`).
  void ouvrirLeClavier(WidgetTester tester, {double dp = 300}) {
    tester.view.viewInsets = FakeViewPadding(
      bottom: dp * tester.view.devicePixelRatio,
    );
    addTearDown(tester.view.resetViewInsets);
  }

  // Les deux paysages sont les tailles où la modale débordait ; les portraits
  // étroits couvrent le débordement horizontal du titre payeur.
  const surfaces = <Size>[
    Size(360, 640), // petit téléphone portrait
    Size(411, 731), // téléphone portrait
    Size(640, 360), // petit téléphone paysage — 218 dp de débordement
    Size(731, 411), // téléphone paysage — 167 dp de débordement
    Size(800, 600), // petite tablette
    Size(1280, 800), // tablette paysage (cible du projet)
  ];

  for (final surface in surfaces) {
    testWidgets('$surface : rien ne déborde, clavier fermé', (tester) async {
      await ouvrir(tester, surface);
      expect(tester.takeException(), isNull);
    });

    testWidgets('$surface : rien ne déborde, clavier ouvert', (tester) async {
      ouvrirLeClavier(tester);
      await ouvrir(tester, surface);
      expect(
        tester.takeException(),
        isNull,
        reason:
            'sous le seuil, en-tête et pied doivent rejoindre le défilement',
      );
    });
  }

  testWidgets('paysage, clavier ouvert : le bouton d\'encaissement reste '
      'atteignable en défilant', (tester) async {
    ouvrirLeClavier(tester);
    await ouvrir(tester, const Size(731, 411));

    expect(tester.takeException(), isNull);
    // Le pied a rejoint le défilement : il existe toujours, donc l'encaissement
    // reste possible — c'est ce que le débordement mettait en péril.
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(find.byType(FacturationCreatePaymentPayerSection), findsOneWidget);
  });

  testWidgets('téléphone étroit : le titre de la section payeur ne déborde '
      'plus horizontalement', (tester) async {
    await ouvrir(tester, const Size(360, 640));
    expect(tester.takeException(), isNull);
  });
}
