import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_settlement_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

/// Le taux du guichet est LU par tous, CORRIGÉ par presque personne.
///
/// Encaisser applique le taux de l'école ; l'écarter est une autre autorité
/// (`finance.rate.override`). Sans la garde, quiconque tient la caisse pouvait
/// imposer son propre taux sur l'argent qui part en base — l'avertissement de
/// divergence le signalait, il ne le bloquait pas.
final _taux = ExchangeRate(
  base: 'USD',
  quote: 'CDF',
  rateMicros: 2000000000,
  effectiveFrom: DateTime.utc(2026, 9, 15),
  divergenceBandBp: 200,
);

/// Le libellé du bloc, en lecture. Asséré plutôt que le nombre : ce que ce test
/// surveille est le DROIT, pas l'écriture du taux.
const _libelleDuTaux = 'TAUX DU JOUR';
const _boutonCorriger = 'Modifier';

void main() {
  late TextEditingController controller;

  setUp(() => controller = TextEditingController());
  tearDown(() => controller.dispose());

  FacturationRatePair paire({bool editing = false}) => FacturationRatePair(
    rate: _taux,
    referenceRate: _taux,
    controller: controller,
    editing: editing,
    onEdit: () {},
    diverges: false,
  );

  Widget section({bool editing = false}) =>
      TenderSettlementSection(pairs: [paire(editing: editing)]);

  Widget habille(Widget child) => MaterialApp(
    locale: const Locale('fr'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );

  Widget avecDroits(Widget child, {required List<String>? permissions}) {
    final bloc = _MockAuthBloc();
    final state = AuthState(
      status: AuthStatus.authenticated,
      permissions: permissions,
    );
    when(() => bloc.state).thenReturn(state);
    whenListen(bloc, Stream<AuthState>.value(state), initialState: state);
    return habille(BlocProvider<AuthBloc>.value(value: bloc, child: child));
  }

  testWidgets('avec le droit : le taux se corrige', (tester) async {
    await tester.pumpWidget(
      avecDroits(section(), permissions: const ['finance.rate.override']),
    );

    expect(find.text(_boutonCorriger), findsOneWidget);
    expect(find.text(_libelleDuTaux), findsOneWidget);
  });

  testWidgets('sans le droit : le taux se LIT, il ne se corrige pas', (
    tester,
  ) async {
    // Le profil du caissier : il encaisse, il ne réécrit pas la vérité
    // monétaire de l'école.
    await tester.pumpWidget(
      avecDroits(
        section(),
        permissions: const ['finance.payment.write', 'finance.grid.read'],
      ),
    );

    expect(find.text(_boutonCorriger), findsNothing);
    // ⚠️ Le repli n'est PAS le vide : masquer le taux lui-même laisserait le
    // caissier appliquer un chiffre qu'il ne voit pas.
    expect(find.text(_libelleDuTaux), findsOneWidget);
  });

  testWidgets('droits inconnus (null) : rien à corriger', (tester) async {
    // Tout le parc est dans cet état au premier démarrage post-migration.
    await tester.pumpWidget(avecDroits(section(), permissions: null));

    expect(find.text(_boutonCorriger), findsNothing);
    expect(find.text(_libelleDuTaux), findsOneWidget);
  });

  testWidgets('une boîte DÉJÀ ouverte n\'est pas modifiable sans le droit', (
    tester,
  ) async {
    // Garder la porte ne garde pas le geste : si la garde n'entourait que le
    // bouton, un droit retiré en cours de session laisserait le champ ouvert
    // et saisissable.
    await tester.pumpWidget(
      avecDroits(
        section(editing: true),
        permissions: const ['finance.payment.write'],
      ),
    );

    expect(find.byType(CurrencyField), findsNothing);
    expect(find.text(_libelleDuTaux), findsOneWidget);
  });

  testWidgets('la même boîte ouverte reste modifiable AVEC le droit', (
    tester,
  ) async {
    // La contre-épreuve : sans elle, le test précédent passerait aussi si la
    // boîte ne s'ouvrait jamais, pour n'importe quelle raison.
    await tester.pumpWidget(
      avecDroits(
        section(editing: true),
        permissions: const ['finance.rate.override'],
      ),
    );

    expect(find.byType(CurrencyField), findsOneWidget);
  });

  testWidgets('sans AuthBloc dans l\'arbre : transparent', (tester) async {
    // Convention du socle, et la raison pour laquelle les tests de la page
    // d'encaissement restent verts sans être touchés : ils montent la page
    // seule, sans session.
    await tester.pumpWidget(habille(section()));

    expect(find.text(_boutonCorriger), findsOneWidget);
  });
}
