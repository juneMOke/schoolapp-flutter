import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/finance/domain/entities/finance_till.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_receipts_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/finance_till_report_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/finance_till_receipts_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _StubReportCubit extends MockCubit<FinanceTillReportState>
    implements FinanceTillReportCubit {}

class _StubReceiptsBloc
    extends MockBloc<FinanceTillReceiptsEvent, FinanceTillReceiptsState>
    implements FinanceTillReceiptsBloc {}

TillReceipt _receipt(String id, DateTime paidAt) => TillReceipt(
  paymentId: id,
  paidAt: paidAt,
  source: 'BILLING',
  amount: 4000,
  currency: 'USD',
  receiptNumber: 'ETL-RC-2627-$id',
  studentName: 'Ilunga Kasongo Esther',
);

/// La colonne Date de la caisse : l'heure du versement, lue à Kinshasa.
void main() {
  Future<void> pump(WidgetTester tester, List<TillReceipt> receipts) async {
    final state = FinanceTillReceiptsState(
      status: FinanceTillReceiptsStatus.success,
      totalElements: receipts.length,
      totalPages: 1,
      receipts: receipts,
    );
    final receiptsBloc = _StubReceiptsBloc();
    when(() => receiptsBloc.state).thenReturn(state);
    whenListen(
      receiptsBloc,
      const Stream<FinanceTillReceiptsState>.empty(),
      initialState: state,
    );
    final reportCubit = _StubReportCubit();
    when(() => reportCubit.state).thenReturn(const FinanceTillReportState());
    whenListen(
      reportCubit,
      const Stream<FinanceTillReportState>.empty(),
      initialState: const FinanceTillReportState(),
    );

    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<FinanceTillReceiptsBloc>.value(value: receiptsBloc),
          BlocProvider<FinanceTillReportCubit>.value(value: reportCubit),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: SingleChildScrollView(
              child: FinanceTillReceiptsSection(
                tillTotals: const [],
                // 10 h 00 à Kinshasa, le 23 octobre 2026.
                now: () => DateTime.utc(2026, 10, 23, 9),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('un versement du jour ne montre que son heure, à Kinshasa', (
    tester,
  ) async {
    await pump(tester, [_receipt('000184', DateTime.utc(2026, 10, 23, 7, 41))]);

    expect(find.text('08:41'), findsOneWidget);
    expect(find.text('23/10/2026'), findsNothing);
  });

  testWidgets('un autre jour garde sa date, l\'heure en plus', (tester) async {
    await pump(tester, [_receipt('000183', DateTime.utc(2026, 10, 20, 13, 5))]);

    expect(find.text('20/10 14:05'), findsOneWidget);
  });

  testWidgets('23 h 30 UTC se range au lendemain, comme la caisse serveur', (
    tester,
  ) async {
    // Le serveur agrège `paid_at AT TIME ZONE 'Africa/Kinshasa'` : la ligne
    // doit tomber dans la même journée que son total.
    await pump(tester, [
      _receipt('000182', DateTime.utc(2026, 10, 21, 23, 30)),
    ]);

    expect(find.text('22/10 00:30'), findsOneWidget);
  });
}
