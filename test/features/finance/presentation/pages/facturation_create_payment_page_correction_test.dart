import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/money/money.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/ticket_print_trace_use_cases.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/ticket_print_status_cubit.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_origin.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/payment_correction_reason.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/payment_correction_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/correct_payment_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_state.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payment_correction_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_create_payment_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_payment_correction_context.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_create_payment_page.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_create_payment_charge_allocation_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockFinanceOfflineBloc
    extends MockBloc<FinanceOfflineEvent, FinanceOfflineState>
    implements FinanceOfflineBloc {}

class _MockCorrect extends Mock implements CorrectPaymentUseCase {}

class _MockPrintedAt extends Mock implements TicketPrintedAtUseCase {}

/// « Corriger » réutilise la page d'encaissement : pré-remplie avec l'origine,
/// tranches rouvertes, un motif obligatoire, et un seul geste.
void main() {
  late _MockFinanceOfflineBloc offline;
  late _MockCorrect correct;

  setUpAll(() {
    registerFallbackValue(
      const PaymentCorrectionDraft(
        paymentId: 'x',
        reason: PaymentCorrectionReason.other,
      ),
    );
  });

  setUp(() {
    offline = _MockFinanceOfflineBloc();
    when(() => offline.state).thenReturn(const FinanceOfflineInitial());
    correct = _MockCorrect();
    when(() => correct(any())).thenAnswer(
      (_) async => const Right(
        PaymentCorrectionOutcome(
          correctionId: 'pc-1',
          replacementPaymentId: 'p-2',
        ),
      ),
    );
    // Le résultat propose le ticket du remplaçant.
    final printedAt = _MockPrintedAt();
    when(() => printedAt(any())).thenAnswer((_) async => null);
    getIt.registerFactory<TicketPrintStatusCubit>(
      () => TicketPrintStatusCubit(printedAt),
    );
  });

  tearDown(() async => getIt.reset());

  // L'origine a soldé cette tranche ; elle arrive ici rouverte, comme le
  // parcours de la fiche la prépare.
  const charge = StudentCharge(
    id: 'T1',
    studentId: 'stu-1',
    academicYearId: 'ay-1',
    schoolLevelId: 'lvl-1',
    schoolLevelGroupId: 'grp-1',
    feeTariffId: 'tar-1',
    feeCode: 'SCOLARITE',
    label: 'Scolarité T1',
    expectedAmountInCents: 15000,
    amountPaidInCents: 0,
    currency: 'USD',
    status: StudentChargeStatus.due,
  );

  final correction = FacturationPaymentCorrectionContext(
    origin: const PaymentCorrectionOrigin(
      paymentId: 'p-1',
      studentId: 'stu-1',
      academicYearId: 'ay-1',
      paidAt: '2026-09-25T12:11:41Z',
      payerFirstName: 'Marie',
      payerLastName: 'Tshiala',
      allocations: [
        PaymentCorrectionOriginAllocation(
          studentChargeId: 'T1',
          feeCode: 'SCOLARITE',
          amountInCents: 15000,
          currency: 'USD',
        ),
      ],
    ),
    originAmounts: MoneyBag.of([Money.parse(15000, 'USD')]),
    originPaidAt: DateTime.utc(2026, 9, 25, 12, 11, 41),
  );

  Future<void> open(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<FinanceOfflineBloc>.value(value: offline),
          BlocProvider(create: (_) => PaymentCorrectionCubit(correct)),
        ],
        child: MaterialApp(
          locale: const Locale('fr'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: FacturationCreatePaymentView(
            now: DateTime.utc(2026, 9, 26, 8),
            intent: FacturationCreatePaymentIntent(
              studentId: 'stu-1',
              academicYearId: 'ay-1',
              firstName: 'Gloredi',
              lastName: 'Tshiala',
              surname: 'Mbuyi',
              levelName: '6e A',
              levelGroupName: 'Secondaire',
              studentCharges: const [charge],
              correction: correction,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  EteeloButton cta(WidgetTester tester) => tester
      .widgetList<EteeloButton>(find.byType(EteeloButton))
      .singleWhere((b) => b.icon == Icons.repeat_rounded);

  Finder amountField() => find
      .descendant(
        of: find.byType(FacturationCreatePaymentChargeAllocationLine),
        matching: find.byType(TextField),
      )
      .first;

  Future<void> choose(WidgetTester tester, PaymentCorrectionReason r) async {
    final chip = find.byKey(ValueKey('payment-correction-reason-${r.code}'));
    await tester.ensureVisible(chip);
    await tester.tap(chip);
    await tester.pump();
  }

  testWidgets('l origine est pré-remplie : payeur, montant, bouton', (
    tester,
  ) async {
    await open(tester);

    expect(find.text('Tshiala'), findsWidgets);
    expect(tester.widget<TextField>(amountField()).controller!.text, '150');
    expect(cta(tester).label, 'Annuler et remplacer');
  });

  testWidgets('« Mauvais élève » n est pas proposé tant que l écran ne sait '
      'pas changer d élève', (tester) async {
    await open(tester);

    expect(find.text('Mauvais montant'), findsOneWidget);
    expect(find.text('Mauvais élève'), findsNothing);
  });

  testWidgets('sans changement, c est Annuler le bon geste', (tester) async {
    await open(tester);
    await choose(tester, PaymentCorrectionReason.wrongAmount);

    expect(cta(tester).onPressed, isNull);
    expect(find.textContaining('Modifiez au moins un élément'), findsOneWidget);
  });

  testWidgets('le cas Gloredi : 150 \$ saisis, 50 \$ reçus', (tester) async {
    await open(tester);
    await tester.enterText(amountField(), '50');
    await tester.pump();
    await choose(tester, PaymentCorrectionReason.wrongAmount);

    // L'écart se dit, neutre.
    expect(
      find.byKey(const ValueKey('payment-correction-gap')),
      findsOneWidget,
    );
    expect(cta(tester).onPressed, isNotNull);

    await tester.tap(find.byWidget(cta(tester)));
    await tester.pump();

    final draft =
        verify(() => correct(captureAny())).captured.single
            as PaymentCorrectionDraft;
    expect(draft.paymentId, 'p-1');
    expect(draft.reason, PaymentCorrectionReason.wrongAmount);
    final replacement = draft.replacement!;
    expect(replacement.allocations.single.amountInCents, 5000);
    expect(replacement.allocations.single.studentChargeId, 'T1');
    // Même jour : l'instant d'origine est repris (D2).
    expect(replacement.paidAt, '2026-09-25T12:11:41Z');
    expect(replacement.payerLastName, 'Tshiala');

    // Un succès LOCAL, et le ticket du remplaçant à imprimer.
    await tester.pump();
    expect(find.text('Versement corrigé'), findsOneWidget);
  });
}
