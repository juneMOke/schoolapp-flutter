import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_charge_line.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_charges_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _FakeChargesBloc extends Cubit<StudentChargesState>
    implements StudentChargesBloc {
  _FakeChargesBloc(super.initial);

  @override
  void add(StudentChargesEvent event) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTitlesCubit extends Cubit<FeeSectionTitlesState>
    implements FeeSectionTitlesCubit {
  _FakeTitlesCubit(super.initial);

  @override
  Future<void> load() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// La section « Frais de l'élève », repliée par nature (GF-3/GF-5).
void main() {
  StudentCharge charge({
    required String id,
    String feeCode = 'TUITION',
    String label = '',
    String? tariffCode,
    double expected = 50000,
    double paid = 0,
  }) => StudentCharge(
    id: id,
    studentId: 's-1',
    academicYearId: 'y-1',
    schoolLevelId: 'lvl-1',
    schoolLevelGroupId: 'grp-1',
    feeTariffId: 't-$id',
    feeTariffCode: tariffCode,
    feeCode: feeCode,
    label: label,
    expectedAmountInCents: expected,
    amountPaidInCents: paid,
    currency: 'CDF',
    // Miroir serveur volontairement FAUX partout dans ce fichier : rien ne le
    // recalcule après un encaissement local, et l'écran ne doit plus le lire.
    status: StudentChargeStatus.due,
  );

  StudentChargesState success(List<StudentCharge> charges) =>
      StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: charges,
      );

  late _FakeChargesBloc chargesBloc;
  late _FakeTitlesCubit titlesCubit;

  Future<void> pump(
    WidgetTester tester,
    List<StudentCharge> charges, {
    Map<String, String> titles = const {},
  }) async {
    chargesBloc = _FakeChargesBloc(success(charges));
    titlesCubit = _FakeTitlesCubit(FeeSectionTitlesState(titles: titles));

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<StudentChargesBloc>.value(value: chargesBloc),
            BlocProvider<FeeSectionTitlesCubit>.value(value: titlesCubit),
          ],
          child: const Scaffold(
            body: SingleChildScrollView(
              child: FacturationDetailChargesSection(
                studentId: 's-1',
                academicYearId: 'y-1',
                onViewChargeRequested: _noop,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  tearDown(() async {
    await chargesBloc.close();
    await titlesCubit.close();
  });

  testWidgets('replie les tranches sous leur nature', (tester) async {
    await pump(tester, [
      charge(id: '1', label: 'Minerval — 1/2', tariffCode: 'T1'),
      charge(id: '2', label: 'Minerval — 2/2', tariffCode: 'T2'),
      charge(id: '3', feeCode: 'CANTEEN', label: 'Cantine annuelle'),
    ]);

    // Une nature repliée, une nature d'une seule tranche restée nue.
    expect(find.text('Frais de scolarité · 2 tranches'), findsOneWidget);
    expect(find.text('Cantine annuelle'), findsOneWidget);
    expect(find.byType(FacturationChargeLine), findsOneWidget);
  });

  testWidgets('le titre de l\'école coiffe la nature quand il est connu', (
    tester,
  ) async {
    await pump(
      tester,
      [charge(id: '1'), charge(id: '2')],
      titles: const {'TUITION': 'Frais scolaires annuels'},
    );

    expect(find.text('Frais scolaires annuels · 2 tranches'), findsOneWidget);
  });

  testWidgets('LE TEST DU LOT : le pli SURVIT à une relecture silencieuse', (
    tester,
  ) async {
    // Cette section est relue sans bruit à chaque signal de revalidation et
    // après chaque encaissement. Un état de pli porté dans le `builder` se
    // reconstruirait à chaque émission et replierait tout sous les doigts de
    // l'opérateur, sans qu'il ait rien fait.
    final charges = [
      charge(id: '1', label: 'Minerval — 1/2', tariffCode: 'T1'),
      charge(id: '2', label: 'Minerval — 2/2', tariffCode: 'T2'),
    ];
    await pump(tester, charges);

    await tester.tap(find.text('Frais de scolarité · 2 tranches'));
    await tester.pumpAndSettle();
    expect(find.text('Minerval — 1/2 (T1)'), findsOneWidget);

    // La relecture : même contenu, nouvelle instance de liste — exactement ce
    // que le loader émet.
    chargesBloc.emit(success(List<StudentCharge>.from(charges)));
    await tester.pumpAndSettle();

    expect(
      find.text('Minerval — 1/2 (T1)'),
      findsOneWidget,
      reason: 'Le pli suit la nature, pas le cycle de vie du builder.',
    );
  });

  testWidgets('le résumé compte natures, tranches et RESTE composé', (
    tester,
  ) async {
    await pump(tester, [
      charge(id: '1', expected: 50000, paid: 50000),
      charge(id: '2', expected: 50000, paid: 0),
      charge(id: '3', feeCode: 'CANTEEN', expected: 30000, paid: 0),
    ]);

    // Deux natures, trois tranches, deux tranches non soldées — et le miroir
    // serveur dit DUE sur les trois.
    expect(
      find.text('2 frais · 3 tranches · 2 restent à régler'),
      findsOneWidget,
    );
  });

  testWidgets('tout soldé : le résumé le dit, malgré le miroir', (
    tester,
  ) async {
    await pump(tester, [
      charge(id: '1', expected: 50000, paid: 50000),
      charge(id: '2', expected: 30000, paid: 30000, feeCode: 'CANTEEN'),
    ]);

    expect(
      find.text('2 frais · 2 tranches · tout est soldé'),
      findsOneWidget,
      reason:
          'Les trois créances portent encore le statut DUE du serveur : le '
          'résumé ne doit plus le lire.',
    );
  });
}

void _noop(StudentCharge _) {}
