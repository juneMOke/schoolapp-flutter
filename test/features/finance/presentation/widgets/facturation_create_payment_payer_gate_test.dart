import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_state.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_allocation_line.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockPaymentsBloc extends MockBloc<PaymentsEvent, PaymentsState>
    implements PaymentsBloc {}

class _MockFinanceOfflineBloc
    extends MockBloc<FinanceOfflineEvent, FinanceOfflineState>
    implements FinanceOfflineBloc {}

/// Le téléphone du payeur est OBLIGATOIRE à l'encaissement.
///
/// Ce n'est pas un confort d'affichage : le numéro est recopié sur le versement
/// et n'est plus corrigeable après coup. Un numéro tronqué partirait en base et
/// vers le serveur en E.164 invalide, sans aucun moyen de rappeler le payeur —
/// d'où une garde sur le CTA, et non un simple avertissement.
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

  Future<void> ouvrir(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
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
              studentCharges: [charge('1')],
            ),
            onPaymentCreated: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  /// Le CTA d'encaissement, reconnu par son variant primaire dans le pied.
  /// `onPressed == null` est la seule lecture qui fasse foi : c'est ce que le
  /// framework consulte pour laisser ou non passer le tap.
  bool collectEnabled(WidgetTester tester) {
    final buttons = tester
        .widgetList<EteeloButton>(find.byType(EteeloButton))
        .where((b) => b.icon == Icons.account_balance_wallet_outlined);
    expect(buttons, hasLength(1));
    return buttons.single.onPressed != null;
  }

  /// Le champ visé PAR SON LIBELLÉ, jamais par sa position dans l'arbre : la
  /// modale porte aussi le champ de montant d'un frais, et un index se
  /// décalerait au premier champ ajouté.
  Finder champParLibelle(String label) => find.descendant(
    of: find.byWidgetPredicate(
      (widget) => widget is EteeloTextInput && widget.label == label,
    ),
    matching: find.byType(TextField),
  );

  Future<void> remplirIdentite(WidgetTester tester) async {
    await tester.enterText(champParLibelle('Nom'), 'Kabongo');
    await tester.enterText(champParLibelle('Prénom'), 'Joseph');
    await tester.pump();
  }

  Future<void> cocherLePremierFrais(WidgetTester tester) async {
    // `.first` sur le résultat de `descendant`, jamais sur le `matching` : posé
    // à l'intérieur, il désignerait le premier InkWell de TOUT l'arbre, qui
    // n'est pas dans la ligne — le finder ne trouve alors rien.
    final coche = find
        .descendant(
          of: find.byType(FacturationCreatePaymentChargeAllocationLine),
          matching: find.byType(InkWell),
        )
        .first;
    // La modale DÉFILE : sans ce cadrage, le tap tombe à côté, le frais n'est
    // pas coché, le total reste nul — et la garde du CTA passerait au vert
    // pour la mauvaise raison, en ne prouvant plus rien du téléphone.
    await tester.ensureVisible(coche);
    await tester.pumpAndSettle();
    await tester.tap(coche);
    await tester.pumpAndSettle();
  }

  /// `EteeloPhoneInput` ne fait taper que la partie NATIONALE : c'est lui qui
  /// recompose l'E.164 dans le contrôleur de l'appelant.
  ///
  /// On vise le champ PAR SON widget, jamais par sa position : le dernier
  /// `TextField` de l'arbre est celui du montant d'un frais, pas le téléphone —
  /// la saisie serait partie dans l'allocation, et le test aurait prouvé le
  /// contraire de ce qu'il annonce.
  Future<void> saisirTelephone(WidgetTester tester, String national) async {
    await tester.enterText(
      find.descendant(
        of: find.byType(EteeloPhoneInput),
        matching: find.byType(TextField),
      ),
      national,
    );
    await tester.pump();
  }

  testWidgets('identité et montant ne suffisent pas : sans numéro, on '
      'n\'encaisse pas', (tester) async {
    await ouvrir(tester);
    await remplirIdentite(tester);
    await cocherLePremierFrais(tester);

    expect(collectEnabled(tester), isFalse);
  });

  testWidgets('un numéro COMPLET débloque l\'encaissement', (tester) async {
    await ouvrir(tester);
    await remplirIdentite(tester);
    await cocherLePremierFrais(tester);
    await saisirTelephone(tester, '816939060');

    expect(collectEnabled(tester), isTrue);
  });

  testWidgets('un numéro tronqué laisse le CTA gris et s\'explique', (
    tester,
  ) async {
    await ouvrir(tester);
    await remplirIdentite(tester);
    await cocherLePremierFrais(tester);
    await saisirTelephone(tester, '8169');

    expect(collectEnabled(tester), isFalse);
    // L'erreur se DIT : un bouton gris sans motif laisse le guichetier
    // chercher lequel des cinq champs cloche.
    expect(find.textContaining('9 chiffres'), findsOneWidget);
  });

  /// Le formulaire s'ouvre vierge : accuser le champ avant toute frappe serait
  /// agressif, et l'erreur perdrait son sens quand elle compte vraiment.
  testWidgets('le champ vide ne porte pas encore d\'erreur', (tester) async {
    await ouvrir(tester);
    await remplirIdentite(tester);

    expect(find.textContaining('9 chiffres'), findsNothing);
  });
}
