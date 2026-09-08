import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/provisional_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_trace_use_cases.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_status_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_ticket_print_row.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **Le test qui manquait.**
///
/// La réimpression libre était la première décision du porteur, spécifiée puis
/// perdue entre l'analyse et l'exécution. Rien ne l'a signalé parce que rien ne
/// l'affirmait : les tests portaient tous sur le rattrapage — « un versement
/// déjà servi n'offre RIEN » —, et ils étaient verts.
///
/// Ce fichier tient l'affirmation inverse, qui est celle du produit : un
/// versement déjà imprimé **garde son bouton**, et le dit avec les mots de la
/// réimpression.
class _FakeRepository implements ProvisionalTicketRepository {
  _FakeRepository({this.printedAt});

  final DateTime? printedAt;

  @override
  Future<DateTime?> ticketPrintedAt(String paymentId) async => printedAt;

  @override
  Future<void> markTicketPrinted(String paymentId) async {}

  @override
  Future<Either<Failure, TicketReceiptModel>> buildForPayment({
    required String paymentId,
    required TicketLabels labels,
  }) async => throw UnimplementedError();
}

Future<void> _pump(WidgetTester tester, {DateTime? printedAt}) async {
  final cubit = TicketPrintStatusCubit(
    TicketPrintedAtUseCase(_FakeRepository(printedAt: printedAt)),
  );
  addTearDown(cubit.close);
  await cubit.load('pay-1');

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<TicketPrintStatusCubit>.value(
          value: cubit,
          child: const FacturationTicketPrintRow(paymentId: 'pay-1'),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('un versement jamais imprimé propose un premier tirage', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Imprimer maintenant'), findsOneWidget);
    expect(find.text('Réimprimer le ticket'), findsNothing);
    expect(find.text('Jamais imprimé depuis cette tablette.'), findsOneWidget);
  });

  /// Celui-là aurait échoué depuis le début : la ligne n'existait tout
  /// simplement pas sur un versement déjà servi.
  testWidgets('un versement déjà imprimé garde son bouton, en réimpression', (
    tester,
  ) async {
    await _pump(tester, printedAt: DateTime(2026, 9, 8, 9, 15));

    // Le geste EXISTE. C'est l'assertion qui porte la décision du porteur.
    final button = find.widgetWithText(TextButton, 'Réimprimer le ticket');
    expect(button, findsOneWidget);
    expect(tester.widget<TextButton>(button).onPressed, isNotNull);
    expect(find.text('Imprimer maintenant'), findsNothing);
  });

  /// La mention DATE le papier au lieu de l'interdire — c'est ce qui remplace
  /// la garde de l'ADR-013 : deux papiers indiscernables restent possibles, la
  /// tablette dit désormais quand le dernier est sorti.
  testWidgets('la mention porte la date du dernier tirage', (tester) async {
    await _pump(tester, printedAt: DateTime(2026, 9, 8, 9, 15));

    expect(find.text('Imprimé le 08/09/2026 09:15'), findsOneWidget);
    expect(find.text('Jamais imprimé depuis cette tablette.'), findsNothing);
  });

  /// L'état initial ne doit jamais annoncer une réimpression : entre
  /// l'ouverture de la modale et la réponse de la base, un caissier qui lirait
  /// « Réimprimer » puis « Imprimer maintenant » se demanderait ce qu'il a
  /// manqué.
  testWidgets('avant toute réponse, la ligne annonce un premier tirage', (
    tester,
  ) async {
    final cubit = TicketPrintStatusCubit(
      TicketPrintedAtUseCase(
        _FakeRepository(printedAt: DateTime(2026, 9, 8, 9, 15)),
      ),
    );
    addTearDown(cubit.close);
    // ⚠️ PAS de `load` : c'est l'état initial qu'on regarde.

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<TicketPrintStatusCubit>.value(
            value: cubit,
            child: const FacturationTicketPrintRow(paymentId: 'pay-1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Imprimer maintenant'), findsOneWidget);
  });
}
