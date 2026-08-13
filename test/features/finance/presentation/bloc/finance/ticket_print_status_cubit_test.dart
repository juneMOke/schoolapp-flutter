import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/repositories/provisional_ticket_repository.dart';
import 'package:school_app_flutter/features/documents/domain/ticket/ticket_receipt_model.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_trace_use_cases.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_status_cubit.dart';

/// Ce cubit décide si le guichet voit un bouton qui produit du papier.
///
/// Les deux sens n'ont pas le même coût. Ne PAS proposer un rattrapage
/// légitime ne fait perdre que du confort — le reçu définitif reste
/// accessible. Le proposer à tort ferait ressortir un ticket déjà remis, donc
/// deux papiers indiscernables pour un versement : ce que l'ADR-013 interdit.
/// D'où le défaut prudent, tenu ici comme dans le repository.
class _FakeRepository implements ProvisionalTicketRepository {
  _FakeRepository({this.awaits = true});

  final bool awaits;
  int calls = 0;

  // Ne lève jamais : le repository rattrape déjà toute lecture illisible et
  // répond « pas d'attente ». Un fake qui lèverait testerait un cas que la
  // production ne peut pas produire.
  @override
  Future<bool> awaitsTicketPrint(String paymentId) async {
    calls++;
    return awaits;
  }

  @override
  Future<void> markTicketPrinted(String paymentId) async {}

  @override
  Future<bool> hasPrintedTicket(String paymentId) async => !awaits;

  @override
  Future<Either<Failure, TicketReceiptModel>> buildForPayment({
    required String paymentId,
    required TicketLabels labels,
  }) async => throw UnimplementedError();
}

void main() {
  TicketPrintStatusCubit cubit(_FakeRepository repository) =>
      TicketPrintStatusCubit(AwaitsTicketPrintUseCase(repository));

  test('annonce l attente quand le versement n a pas eu son papier', () async {
    final subject = cubit(_FakeRepository(awaits: true));

    await subject.load('pay-1');

    expect(subject.state.loaded, isTrue);
    expect(subject.state.awaitsPrint, isTrue);
  });

  test('n annonce rien quand le papier est déjà sorti', () async {
    final subject = cubit(_FakeRepository(awaits: false));

    await subject.load('pay-1');

    expect(subject.state.awaitsPrint, isFalse);
  });

  /// L'état initial ne doit jamais laisser croire à une attente : la ligne
  /// apparaîtrait puis disparaîtrait sous les doigts du caissier, qui aurait pu
  /// appuyer entre-temps.
  test('n attend rien tant que la réponse est inconnue', () {
    expect(cubit(_FakeRepository()).state.awaitsPrint, isFalse);
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
  /// premier laisse une trace. Un raccourci qui retirerait la ligne d'office
  /// masquerait le rattrapage d'un papier jamais sorti.
  test('une relecture après tirage reflète la trace réelle', () async {
    final repository = _FakeRepository(awaits: false);
    final subject = cubit(repository);

    await subject.load('pay-1');

    expect(subject.state.awaitsPrint, isFalse);
    expect(repository.calls, 1);
  });
}
