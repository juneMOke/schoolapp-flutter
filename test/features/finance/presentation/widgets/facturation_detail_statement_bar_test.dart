import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_freshness_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_statement_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Faux BLoC de créances : la barre ne fait que lire son état.
class _FakeStudentChargesBloc extends Cubit<StudentChargesState>
    implements StudentChargesBloc {
  _FakeStudentChargesBloc(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLedgerFreshnessCubit extends Cubit<int?>
    implements LedgerFreshnessCubit {
  _FakeLedgerFreshnessCubit() : super(null);

  @override
  Future<void> load(String studentId) async {}
}

StudentCharge _charge() => const StudentCharge(
  id: 'c-1',
  studentId: 's-1',
  academicYearId: 'y-1',
  schoolLevelId: 'lvl-1',
  schoolLevelGroupId: 'grp-1',
  feeTariffId: 'tar-1',
  feeCode: 'TUITION',
  label: 'Frais scolaires',
  expectedAmountInCents: 100000,
  amountPaidInCents: 0,
  currency: 'CDF',
  status: StudentChargeStatus.due,
);

Future<void> _pump(
  WidgetTester tester, {
  required StudentChargesState chargesState,
}) {
  return tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<StudentChargesBloc>(
              create: (_) => _FakeStudentChargesBloc(chargesState),
            ),
            BlocProvider<LedgerFreshnessCubit>(
              create: (_) => _FakeLedgerFreshnessCubit(),
            ),
          ],
          child: const FacturationDetailStatementBar(
            studentId: 's-1',
            academicYearId: 'y-1',
          ),
        ),
      ),
    ),
  );
}

/// Bouton du relevé, retrouvé par son libellé.
Finder _statementButton() => find.ancestor(
  of: find.text('Relevé de compte'),
  matching: find.byType(OutlinedButton),
);

void main() {
  testWidgets('affiche l action quand l élève a des frais', (tester) async {
    await _pump(
      tester,
      chargesState: StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: [_charge()],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Relevé de compte'), findsOneWidget);
    expect(
      find.text(
        'Aucun frais sur l\'année : le relevé ne peut pas être produit.',
      ),
      findsNothing,
    );
  });

  // Le serveur répond 404 quand l'élève n'a aucune créance sur l'année : on
  // éteint plutôt que de laisser cliquer vers une erreur.
  testWidgets('éteint l action et l explique sans aucun frais', (tester) async {
    await _pump(
      tester,
      chargesState: const StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: [],
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Aucun frais sur l\'année : le relevé ne peut pas être produit.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('n explique rien tant que les frais ne sont pas chargés', (
    tester,
  ) async {
    await _pump(
      tester,
      chargesState: const StudentChargesState(
        status: StudentChargesStatus.loading,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Relevé de compte'), findsOneWidget);
    expect(
      find.text(
        'Aucun frais sur l\'année : le relevé ne peut pas être produit.',
      ),
      findsNothing,
    );
  });

  // Chaque émission brûle un numéro de séquence : l'appui ouvre une
  // confirmation, jamais directement la génération.
  testWidgets('demande confirmation avant de générer', (tester) async {
    await _pump(
      tester,
      chargesState: StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: [_charge()],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_statementButton());
    await tester.pumpAndSettle();

    expect(find.text('Générer un relevé de compte ?'), findsOneWidget);
    expect(find.textContaining('nouvelle pièce numérotée'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
  });

  testWidgets('annuler la confirmation ne génère rien', (tester) async {
    await _pump(
      tester,
      chargesState: StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: [_charge()],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_statementButton());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(find.text('Générer un relevé de compte ?'), findsNothing);
    // Aucune visionneuse n'a été ouverte.
    expect(find.text('Préparation du document…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reste lisible en largeur compacte', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await _pump(
      tester,
      chargesState: StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: [_charge()],
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Relevé de compte'), findsOneWidget);
  });
}
