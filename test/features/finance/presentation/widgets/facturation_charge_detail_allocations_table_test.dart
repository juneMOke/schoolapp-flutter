import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/payment_allocations.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_detail_allocations_table.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Table « qui a payé quoi » sur UNE créance : chaque ligne nomme le payeur du
/// versement porteur, et doit désormais donner de quoi le rappeler.
PaymentAllocation _allocation({
  String id = 'a1',
  String lastName = 'Kabongo',
  String firstName = 'Joseph',
  String? phone = '+243816939060',
}) => PaymentAllocation(
  id: id,
  paymentId: 'p1',
  studentChargeId: 'c1',
  feeCode: 'tuition',
  studentChargeLabel: 'Frais de scolarité',
  amountInCents: 12000,
  currency: 'USD',
  payerFirstName: firstName,
  payerLastName: lastName,
  payerPhoneNumber: phone,
  paidAt: DateTime(2026, 8, 12),
);

Future<void> _pump(WidgetTester tester, List<PaymentAllocation> allocations) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          // Largeur étroite, comme dans la popin de détail d'un frais.
          child: SizedBox(
            width: 460,
            child: FacturationChargeDetailAllocationsTable(
              allocations: allocations,
              totalInCents: 12000,
              currency: 'USD',
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('chaque imputation porte le payeur et son numéro', (
    tester,
  ) async {
    await _pump(tester, [_allocation()]);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Kabongo Joseph'), findsOneWidget);
    expect(find.text('+243816939060'), findsOneWidget);
  });

  /// Une imputation venue d'un versement antérieur au palier v28 n'a pas de
  /// numéro à montrer. Dans une table, escamoter la ligne vaut mieux que
  /// répéter « inconnu » à chaque rang.
  testWidgets('sans numéro, la ligne du téléphone disparaît', (tester) async {
    await _pump(tester, [_allocation(phone: null)]);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.phone_outlined), findsNothing);
    expect(find.text('Kabongo Joseph'), findsOneWidget);
  });

  /// Deux versements du même frais par deux payeurs différents : chacun garde
  /// SON numéro. Un repli partagé ferait rappeler la mauvaise personne.
  testWidgets('deux payeurs, deux numéros distincts', (tester) async {
    await _pump(tester, [
      _allocation(),
      _allocation(
        id: 'a2',
        lastName: 'Mbayo',
        firstName: 'Alice',
        phone: '+243997654321',
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('+243816939060'), findsOneWidget);
    expect(find.text('+243997654321'), findsOneWidget);
    expect(find.byIcon(Icons.phone_outlined), findsNWidgets(2));
  });
}
