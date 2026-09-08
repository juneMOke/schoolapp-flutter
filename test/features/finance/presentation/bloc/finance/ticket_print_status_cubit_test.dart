import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/provisional_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_trace_use_cases.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_status_cubit.dart';

/// Ce cubit ne décide plus RIEN.
///
/// Il répondait « ce versement attend-il son premier papier ? », et la ligne
/// d'impression n'apparaissait que sur un « oui ». La réimpression étant libre,
/// le bouton est toujours offert : ce cubit ne fournit plus que les MOTS —
/// « Imprimer maintenant » ou « Réimprimer le ticket », « Jamais imprimé depuis
/// cette tablette » ou « Imprimé le … ».
///
/// Le défaut prudent change donc de sens. Il ne protège plus d'un papier remis
/// deux fois — cela ne se protège plus, cela se date — mais d'un libellé qui
/// changerait sous les doigts du caissier : mieux vaut annoncer un premier
/// tirage et se corriger, que d'annoncer une réimpression sans savoir.
class _FakeRepository implements ProvisionalTicketRepository {
  _FakeRepository({this.printedAt});

  final DateTime? printedAt;
  int calls = 0;

  // Ne lève jamais : le repository rattrape déjà toute lecture illisible et
  // répond `null`. Un fake qui lèverait testerait un cas que la production ne
  // peut pas produire.
  @override
  Future<DateTime?> ticketPrintedAt(String paymentId) async {
    calls++;
    return printedAt;
  }

  @override
  Future<void> markTicketPrinted(String paymentId) async {}

  @override
  Future<Either<Failure, TicketReceiptModel>> buildForPayment({
    required String paymentId,
    required TicketLabels labels,
  }) async => throw UnimplementedError();
}

void main() {
  TicketPrintStatusCubit cubit(_FakeRepository repository) =>
      TicketPrintStatusCubit(TicketPrintedAtUseCase(repository));

  test('un versement jamais imprimé ici ne porte aucune date', () async {
    final subject = cubit(_FakeRepository());

    await subject.load('pay-1');

    expect(subject.state.loaded, isTrue);
    expect(subject.state.printedAt, isNull);
    expect(subject.state.wasPrinted, isFalse);
  });

  test('un papier déjà sorti porte la date de son tirage', () async {
    final at = DateTime(2026, 9, 8, 11, 42);
    final subject = cubit(_FakeRepository(printedAt: at));

    await subject.load('pay-1');

    expect(subject.state.printedAt, at);
    expect(subject.state.wasPrinted, isTrue);
  });

  /// L'état initial ne doit jamais annoncer une réimpression : le libellé
  /// changerait sous les doigts du caissier entre l'ouverture de la modale et
  /// la réponse de la base, et il se demanderait ce qu'il a manqué.
  test('n annonce aucune impression tant que la réponse est inconnue', () {
    expect(cubit(_FakeRepository()).state.wasPrinted, isFalse);
    expect(cubit(_FakeRepository()).state.loaded, isFalse);
  });

  test('un identifiant vide n interroge même pas la base', () async {
    final repository = _FakeRepository();
    final subject = cubit(repository);

    await subject.load('   ');

    expect(repository.calls, isZero);
    expect(subject.state.loaded, isFalse);
  });

  /// Après un tirage, le widget RELIT plutôt que de supposer : il ne sait pas
  /// si la thermique a servi ou si le repli PDF a pris la main, et seul le
  /// premier laisse une trace. Un raccourci qui basculerait le libellé d'office
  /// annoncerait « Réimprimer » sur un papier qui n'est jamais sorti.
  test('une relecture après tirage reflète la trace réelle', () async {
    final repository = _FakeRepository();
    final subject = cubit(repository);

    await subject.load('pay-1');

    expect(subject.state.wasPrinted, isFalse);
    expect(repository.calls, 1);
  });

  /// Le point qui a manqué pendant tout le lot précédent : un versement DÉJÀ
  /// imprimé garde son geste. C'est ce test qui aurait échoué depuis le début.
  test('un versement déjà imprimé garde son geste, en réimpression', () async {
    final subject = cubit(
      _FakeRepository(printedAt: DateTime(2026, 9, 8, 9, 15)),
    );

    await subject.load('pay-1');

    // Rien, dans cet état, ne retire l'action : `wasPrinted` choisit un
    // libellé, il ne ferme pas un bouton.
    expect(subject.state.wasPrinted, isTrue);
    expect(subject.state.loaded, isTrue);
  });
}
