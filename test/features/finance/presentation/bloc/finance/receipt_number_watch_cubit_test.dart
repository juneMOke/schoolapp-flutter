import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/offline/domain/payment_receipt_resolver.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/receipt_number_watch_cubit.dart';

class _Receipts implements PaymentReceiptResolver {
  PaymentReceiptReference reference = const PaymentReceiptReference(
    number: 'PROV-1A2B3C4D',
    status: PaymentReceiptStatus.provisional,
  );
  int reads = 0;

  @override
  Future<PaymentReceiptReference> resolve(String paymentId) async {
    reads++;
    return reference;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _sealed = PaymentReceiptReference(
  number: 'CF-RC-2627-000802',
  status: PaymentReceiptStatus.definitive,
);

/// L'attente du numéro définitif après un encaissement (continuité des tickets
/// RC, lot D). Délais en millisecondes : le minuteur tourne pour de vrai.
void main() {
  late _Receipts receipts;
  late ReceiptNumberWatchCubit watch;

  setUp(() {
    receipts = _Receipts();
    watch = ReceiptNumberWatchCubit(
      receipts,
      every: const Duration(milliseconds: 10),
      giveUpAfter: const Duration(milliseconds: 40),
    );
  });

  tearDown(() => watch.close());

  Future<void> wait(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  /// Attend la phase plutôt qu'un délai fixe : sous la charge de la suite
  /// complète, un minuteur de 10 ms peut tarder bien au-delà de 25 ms. Le
  /// cubit compte ses tics, il n'abandonne donc pas plus tôt pour autant.
  Future<void> reach(ReceiptNumberPhase phase) async {
    if (watch.state.phase == phase) return;
    await watch.stream
        .firstWhere((s) => s.phase == phase)
        .timeout(const Duration(seconds: 5));
  }

  test('déjà scellé : le numéro tout de suite, sans relecture', () async {
    receipts.reference = _sealed;

    await watch.watch('p-1');
    await wait(30);

    expect(watch.state.phase, ReceiptNumberPhase.numbered);
    expect(watch.state.number, 'CF-RC-2627-000802');
    expect(receipts.reads, 1);
  });

  test(
    'l accusé arrive pendant l attente : le numéro, puis plus rien',
    () async {
      await watch.watch('p-1');
      expect(watch.state.phase, ReceiptNumberPhase.waiting);

      receipts.reference = _sealed;
      await reach(ReceiptNumberPhase.numbered);

      expect(watch.state.number, 'CF-RC-2627-000802');
      final reads = receipts.reads;
      await wait(40);
      expect(receipts.reads, reads);
    },
  );

  test('sans accusé dans le délai : renvoi vers la file', () async {
    await watch.watch('p-1');
    await reach(ReceiptNumberPhase.deferred);

    expect(watch.state.number, isNull);
    final reads = receipts.reads;
    await wait(40);
    expect(receipts.reads, reads);
  });

  test('un numéro PROV- n est jamais pris pour le définitif', () async {
    await watch.watch('p-1');
    await wait(15);

    expect(watch.state.phase, ReceiptNumberPhase.waiting);
  });

  test('fermé en cours d attente : plus aucune relecture', () async {
    await watch.watch('p-1');
    await watch.close();
    final reads = receipts.reads;

    await wait(40);

    expect(receipts.reads, reads);
  });
}
