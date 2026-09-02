import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_phone_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_payer_suggestions_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/search_payers_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_state.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_allocation_line.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_create_payment_page.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockFinanceOfflineBloc
    extends MockBloc<FinanceOfflineEvent, FinanceOfflineState>
    implements FinanceOfflineBloc {}

/// Annuaire de test : chaque ouverture de la popin propose le payeur suivant
/// de [queue].
class _FakePayerRepo implements FinanceOfflineRepository {
  final List<List<LocalPayerIdentity>> queue = [];

  @override
  Future<Either<Failure, List<LocalPayerIdentity>>> getPayerSuggestions(
    String studentId, {
    int limit = 8,
  }) async => Right(queue.isEmpty ? const [] : queue.removeAt(0));

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('hors périmètre de cette page');
}

/// Le payeur est FACULTATIF à l'encaissement — son numéro reste gardé sur le
/// FORMAT.
///
/// Depuis la V114 serveur, ni les noms ni le téléphone ne conditionnent le
/// versement : l'exigence se payait comptant au guichet, où la file attend
/// pendant qu'on demande son état civil à qui tend les billets, et où le
/// guichetier finissait par taper « X ». Un payeur ABSENT vaut mieux qu'un
/// payeur INVENTÉ.
///
/// Ce qui reste gardé, et par une garde sur le CTA plutôt qu'un avertissement :
/// le numéro ENTAMÉ mais incomplet. Il est recopié sur le versement et n'est
/// plus corrigeable après coup ; tronqué, il partirait en base et vers le
/// serveur en E.164 invalide, sans aucun moyen de rappeler le payeur. Une
/// absence est une décision, un numéro à moitié tapé est une faute de frappe.
void main() {
  late _MockFinanceOfflineBloc offline;

  late _FakePayerRepo payerRepo;

  setUp(() {
    offline = _MockFinanceOfflineBloc();
    when(() => offline.state).thenReturn(const FinanceOfflineInitial());

    payerRepo = _FakePayerRepo();
    getIt.registerFactory<PayerSearchBloc>(
      () => PayerSearchBloc(
        suggestions: GetPayerSuggestionsUseCase(payerRepo),
        search: SearchPayersUseCase(payerRepo),
      ),
    );
  });

  tearDown(() async => getIt.reset());

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
        providers: [BlocProvider<FinanceOfflineBloc>.value(value: offline)],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FacturationCreatePaymentView(
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

  testWidgets('identité sans numéro : on encaisse quand même', (tester) async {
    await ouvrir(tester);
    await remplirIdentite(tester);
    await cocherLePremierFrais(tester);

    expect(collectEnabled(tester), isTrue);
  });

  /// Le cas que la V114 a ouvert, et le seul qui compte vraiment au comptoir :
  /// quelqu'un tend l'argent, on ne lui demande rien, et l'encaissement part.
  /// Les imputations nomment toujours l'élève et les créances soldées — c'est
  /// là qu'est l'imputabilité, pas dans le nom de qui a tendu les billets.
  testWidgets('AUCUN champ de payeur : l\'encaissement part quand même', (
    tester,
  ) async {
    await ouvrir(tester);
    await cocherLePremierFrais(tester);

    expect(collectEnabled(tester), isTrue);
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

  /// Reprend un payeur de l'annuaire : la popin propose le prochain lot de
  /// [_FakePayerRepo], et on tape la ligne par son nom.
  Future<void> reprendreUnPayeur(WidgetTester tester, String nomComplet) async {
    final cta = find.text('Choisir un payeur');
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();

    final ligne = find.text(nomComplet);
    await tester.ensureVisible(ligne);
    await tester.pumpAndSettle();
    await tester.tap(ligne);
    await tester.pumpAndSettle();
  }

  /// La tolérance au numéro hérité appartient au PAYEUR qui l'a apporté.
  ///
  /// Mémorisée sur la seule chaîne du champ, elle survivait au changement de
  /// payeur : un payeur sans numéro connu ne remplace rien (on n'efface pas ce
  /// qui est déjà tapé), donc le champ gardait le numéro invalide du
  /// précédent — et l'encaissement partait au nom de l'un avec le numéro de
  /// l'autre, sans qu'aucune erreur ne s'affiche.
  testWidgets('changer de payeur retire la tolérance au numéro du précédent', (
    tester,
  ) async {
    payerRepo.queue.addAll([
      // A : numéro hérité INVALIDE (8 chiffres, écrit avant la garde).
      const [
        LocalPayerIdentity(
          lastName: 'Kabongo',
          firstName: 'Joseph',
          phoneNumber: '08169390',
          origin: PayerOrigin.previousPayment,
          paymentCount: 3,
        ),
      ],
      // B : aucun numéro connu (versements antérieurs à la v28).
      const [
        LocalPayerIdentity(
          lastName: 'Mbayo',
          firstName: 'Alice',
          origin: PayerOrigin.previousPayment,
          paymentCount: 1,
        ),
      ],
    ]);

    await ouvrir(tester);
    await cocherLePremierFrais(tester);

    await reprendreUnPayeur(tester, 'Kabongo Joseph');
    // Le numéro hérité INTACT est toléré : exiger un format qu'aucune saisie
    // du guichetier n'a produit bloquerait l'encaissement pour rien.
    expect(collectEnabled(tester), isTrue);

    await reprendreUnPayeur(tester, 'Mbayo Alice');

    // Le champ porte toujours le numéro de A — on n'efface pas ce qu'on ne
    // sait pas remplacer — mais il n'est plus couvert par personne.
    expect(collectEnabled(tester), isFalse);
    expect(find.textContaining('9 chiffres'), findsOneWidget);
  });
}
