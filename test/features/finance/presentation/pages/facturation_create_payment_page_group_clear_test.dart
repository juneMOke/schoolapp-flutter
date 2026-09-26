import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_state.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_create_payment_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockFinanceOfflineBloc
    extends MockBloc<FinanceOfflineEvent, FinanceOfflineState>
    implements FinanceOfflineBloc {}

/// Le bug remonté du guichet : sur une nature à plusieurs tranches, effacer
/// tous les chiffres du montant repliait la nature — et le champ, retiré de
/// l'arbre, emportait le curseur et le clavier avec lui.
///
/// Un champ vidé est une saisie EN COURS, pas un décochage : le caissier efface
/// pour retaper. Seule la case replie la nature.
void main() {
  late _MockFinanceOfflineBloc offline;

  setUp(() {
    offline = _MockFinanceOfflineBloc();
    when(() => offline.state).thenReturn(const FinanceOfflineInitial());
  });

  List<StudentCharge> tranches() => [
    for (final (index, code) in ['T1', 'T2', 'T3'].indexed)
      StudentCharge(
        id: 'sc-${index + 1}',
        studentId: 'stu-1',
        academicYearId: 'ay-1',
        schoolLevelId: 'lvl-1',
        schoolLevelGroupId: 'grp-1',
        feeTariffId: 'tar-${index + 1}',
        feeTariffCode: code,
        feeCode: 'TUITION',
        label: 'Minerval — ${index + 1}/3',
        expectedAmountInCents: 50000,
        amountPaidInCents: 0,
        currency: 'CDF',
        status: StudentChargeStatus.due,
      ),
  ];

  Future<void> ouvrir(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [BlocProvider<FinanceOfflineBloc>.value(value: offline)],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FacturationCreatePaymentView(
            intent: FacturationCreatePaymentIntent(
              studentId: 'stu-1',
              academicYearId: 'ay-1',
              firstName: 'Kevin',
              lastName: 'Makela',
              surname: 'Mbuyi',
              levelName: '5e A',
              levelGroupName: 'Primaire',
              studentCharges: tranches(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Le champ « Montant réglé » de la NATURE — ciblé par son intitulé : le
  /// premier champ de la page est celui du payeur.
  Finder champDuGroupe() =>
      find.widgetWithText(TextField, 'Montant réglé').first;

  bool aLeCurseur(WidgetTester tester, Finder field) {
    final editable = find.descendant(
      of: field,
      matching: find.byType(EditableText),
    );
    return tester.widget<EditableText>(editable).focusNode.hasFocus;
  }

  testWidgets('effacer tous les chiffres garde la nature ouverte, le champ '
      'et son curseur', (tester) async {
    await ouvrir(tester);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(champDuGroupe());
    await tester.pumpAndSettle();
    expect(aLeCurseur(tester, champDuGroupe()), isTrue);

    await tester.enterText(champDuGroupe(), '');
    await tester.pumpAndSettle();

    expect(champDuGroupe(), findsOneWidget, reason: 'la nature s\'est repliée');
    expect(aLeCurseur(tester, champDuGroupe()), isTrue);
    expect(tester.testTextInput.isVisible, isTrue, reason: 'clavier fermé');
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isTrue);

    // Le caissier retape : la ventilation repart de là.
    await tester.enterText(champDuGroupe(), '700');
    await tester.pumpAndSettle();
    expect(find.textContaining('500'), findsWidgets);
    expect(tester.widget<TextField>(champDuGroupe()).controller!.text, '700');
  });

  testWidgets('la case, elle, replie toujours la nature', (tester) async {
    await ouvrir(tester);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.enterText(champDuGroupe(), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Montant réglé'), findsNothing);
    expect(tester.widget<Checkbox>(find.byType(Checkbox).first).value, isFalse);
  });
}
