import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_dashboard_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/recouvrement_fee_rates.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/dashboard/recouvrement_fee_rates_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockBloc
    extends MockBloc<RecouvrementDashboardEvent, RecouvrementDashboardState>
    implements RecouvrementDashboardBloc {}

RecouvrementFeeRate rate(
  String feeCode, {
  String currency = 'USD',
  int expected = 30000,
  int paid = 12000,
  int remaining = 18000,
}) => RecouvrementFeeRate(
  feeCode: feeCode,
  currency: currency,
  expectedInCents: expected,
  paidInCents: paid,
  remainingInCents: remaining,
);

RecouvrementCurrencyGroup group(
  String currency,
  List<RecouvrementFeeRate> fees,
) {
  var expected = 0;
  var paid = 0;
  var remaining = 0;
  for (final fee in fees) {
    expected += fee.expectedInCents;
    paid += fee.paidInCents;
    remaining += fee.remainingInCents;
  }
  return RecouvrementCurrencyGroup(
    currency: currency,
    fees: fees,
    expectedInCents: expected,
    paidInCents: paid,
    remainingInCents: remaining,
  );
}

void main() {
  late _MockBloc bloc;

  setUp(() => bloc = _MockBloc());

  Future<void> pump(
    WidgetTester tester, {
    required List<RecouvrementCurrencyGroup> groups,
    EnrollmentLoadStatus status = EnrollmentLoadStatus.success,
    List<String> feeCodes = const ['TUITION'],
  }) async {
    whenListen(
      bloc,
      const Stream<RecouvrementDashboardState>.empty(),
      initialState: RecouvrementDashboardState(
        status: status,
        lastQuery: RecouvrementQuery(
          academicYearId: 'ay-1',
          feeCodes: feeCodes,
        ),
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BlocProvider<RecouvrementDashboardBloc>.value(
              value: bloc,
              child: RecouvrementFeeRatesSection(groups: groups),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('deux devises font DEUX groupes, jamais un classement unique', (
    tester,
  ) async {
    await pump(
      tester,
      feeCodes: const ['TUITION', 'REGISTRATION'],
      groups: [
        group('CDF', [
          rate(
            'REGISTRATION',
            currency: 'CDF',
            expected: 5000000,
            paid: 1000000,
            remaining: 4000000,
          ),
        ]),
        group('USD', [rate('TUITION')]),
      ],
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(
      find.text(l10n.recouvrementCurrencyGroupTitle('FC')),
      findsOneWidget,
    );
    expect(
      find.text(l10n.recouvrementCurrencyGroupTitle(r'$')),
      findsOneWidget,
    );
  });

  testWidgets('un poste sans attendu pose un TIRET, jamais « 100 % »', (
    tester,
  ) async {
    await pump(
      tester,
      groups: [
        group('USD', [
          rate('TUITION'),
          rate('DONATION', expected: 0, paid: 5000, remaining: 0),
        ]),
      ],
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l10n.recouvrementNoAmountDash), findsOneWidget);
    expect(find.text(l10n.recouvrementRateNoExpectation), findsOneWidget);
    expect(
      find.text('100 %'),
      findsNothing,
      reason: 'un poste dormant recouvré à 100 % serait un contresens',
    );
  });

  testWidgets('chaque barre dit son taux et son reste en toutes lettres', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(
      tester,
      groups: [
        group('USD', [rate('TUITION')]),
      ],
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    // La barre est une image : son sens doit vivre dans l'étiquette, jamais
    // dans la seule longueur. On vérifie que le poste ET son taux y sont.
    expect(
      find.bySemanticsLabel(RegExp('${l10n.studentChargeFeeCodeTuition}.*40')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('rien n\'est rendu tant que la lecture n\'a pas abouti', (
    tester,
  ) async {
    await pump(
      tester,
      status: EnrollmentLoadStatus.loading,
      groups: [
        group('USD', [rate('TUITION')]),
      ],
    );

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l10n.recouvrementRatesTitle), findsNothing);
  });

  testWidgets('aucun groupe ⇒ aucune section vide', (tester) async {
    await pump(tester, groups: const []);

    final l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    expect(find.text(l10n.recouvrementRatesTitle), findsNothing);
  });
}
