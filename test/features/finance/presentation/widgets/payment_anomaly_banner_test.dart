import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_anomaly.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payment_anomalies_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/payment_anomaly_banner.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Faux AuthBloc : le bandeau ne lit que le statut de session.
class _FakeAuthBloc extends Bloc<AuthEvent, AuthState> implements AuthBloc {
  _FakeAuthBloc(AuthState initial) : super(initial);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAnomaliesCubit extends Cubit<PaymentAnomaliesState>
    implements PaymentAnomaliesCubit {
  _FakeAnomaliesCubit(super.initialState);

  final acknowledged = <String>[];

  @override
  Future<void> acknowledge(String anomalyId) async {
    acknowledged.add(anomalyId);
    emit(
      PaymentAnomaliesState(
        loaded: true,
        open: state.open.where((a) => a.id != anomalyId).toList(),
      ),
    );
  }

  @override
  Future<void> refresh() async {}
}

PaymentAnomaly _anomaly({
  String id = 'a-1',
  String? cashier = 'Jean',
  String? reason = 'Montant supérieur au reste dû',
}) => PaymentAnomaly(
  id: id,
  paymentId: 'p-1',
  studentId: 's-1',
  kind: PaymentAnomalyKind.overpayment,
  excessInCents: 25000,
  currency: 'CDF',
  reason: reason,
  cashierFirstName: cashier,
  cashierLastName: cashier == null ? null : 'Kabeya',
  detectedAt: 10,
);

Future<_FakeAnomaliesCubit> _pump(
  WidgetTester tester,
  List<PaymentAnomaly> open, {
  AuthStatus authStatus = AuthStatus.authenticated,
}) async {
  final cubit = _FakeAnomaliesCubit(
    PaymentAnomaliesState(loaded: true, open: open),
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (_) => _FakeAuthBloc(AuthState(status: authStatus)),
          ),
          BlocProvider<PaymentAnomaliesCubit>.value(value: cubit),
        ],
        child: const PaymentAnomalyBanner(
          child: Scaffold(body: Text('contenu')),
        ),
      ),
    ),
  );
  await tester.pump();
  return cubit;
}

void main() {
  testWidgets('reste invisible sans anomalie ouverte', (tester) async {
    await _pump(tester, const []);

    expect(find.text('Trop-perçu à arbitrer'), findsNothing);
    expect(find.text('contenu'), findsOneWidget);
  });

  testWidgets('annonce le trop-perçu et nomme le caissier', (tester) async {
    await _pump(tester, [_anomaly()]);

    expect(find.text('Trop-perçu à arbitrer'), findsOneWidget);
    expect(find.textContaining('Jean Kabeya'), findsOneWidget);
    expect(find.textContaining('Montant supérieur'), findsOneWidget);
  });

  // C'est tout l'intérêt de ce bandeau : aucune croix, aucun glissement, aucune
  // fermeture par tap à côté. La feuille de reprise de synchro, elle, se ferme
  // d'un tap et son motif s'efface d'un clic sur « Réessayer ».
  testWidgets('n offre aucun moyen de fermer sans traiter', (tester) async {
    await _pump(tester, [_anomaly()]);

    expect(find.byIcon(Icons.close), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.text('Traité'), findsOneWidget);
  });

  testWidgets('le traitement éteint le bandeau', (tester) async {
    final cubit = await _pump(tester, [_anomaly()]);

    await tester.tap(find.text('Traité'));
    await tester.pump();

    expect(cubit.acknowledged, ['a-1']);
    expect(find.text('Trop-perçu à arbitrer'), findsNothing);
  });

  // Une à la fois, mais on dit combien il en reste : sinon l'opérateur croit
  // avoir fini au premier traitement.
  testWidgets('signale les autres anomalies en attente', (tester) async {
    await _pump(tester, [_anomaly(), _anomaly(id: 'a-2')]);

    expect(find.textContaining('1 autre'), findsOneWidget);
  });

  testWidgets('reste lisible sans caissier ni motif connus', (tester) async {
    await _pump(tester, [_anomaly(cashier: null, reason: null)]);

    expect(find.text('Trop-perçu à arbitrer'), findsOneWidget);
    expect(find.textContaining('dépasse le reste dû'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  // Le bandeau nomme un caissier et un motif d'anomalie FINANCIÈRE, et son
  // bouton « Traité » écrit un accusé en base au nom de l'utilisateur courant.
  // Sur l'écran de connexion, il exposerait des données nominatives à qui tient
  // l'appareil et laisserait n'importe qui éteindre l'alerte — au nom d'un uid
  // vide.
  testWidgets('reste invisible hors session authentifiée', (tester) async {
    await _pump(tester, [_anomaly()], authStatus: AuthStatus.unauthenticated);

    expect(find.text('Trop-perçu à arbitrer'), findsNothing);
    expect(find.text('Traité'), findsNothing);
    expect(find.text('contenu'), findsOneWidget);
  });

  testWidgets('reste invisible pendant la vérification de session', (
    tester,
  ) async {
    await _pump(tester, [_anomaly()], authStatus: AuthStatus.loading);

    expect(find.text('Trop-perçu à arbitrer'), findsNothing);
  });
}
