import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_eligibility_cubit.dart';
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

class _FakeEditiqueEligibilityCubit extends Cubit<EditiqueEligibilityState>
    implements EditiqueEligibilityCubit {
  _FakeEditiqueEligibilityCubit(super.initialState);

  @override
  Future<void> resolveForStudent(String studentId) async {}
}

class _FakeSyncStatusCubit extends Cubit<SyncStatusState>
    implements SyncStatusCubit {
  _FakeSyncStatusCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
  EditiqueEligibilityStatus eligibility = EditiqueEligibilityStatus.eligible,
  SyncStatus syncStatus = SyncStatus.synced,
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
            BlocProvider<EditiqueEligibilityCubit>(
              create: (_) => _FakeEditiqueEligibilityCubit(
                EditiqueEligibilityState(status: eligibility),
              ),
            ),
            BlocProvider<SyncStatusCubit>(
              create: (_) =>
                  _FakeSyncStatusCubit(SyncStatusState(status: syncStatus)),
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

  // La garde qui motive tout le lot : un élève encore en attente de synchro
  // porte un uuid client que le serveur ignore — l'appel donnerait un 404.
  testWidgets('éteint l action pour un élève non synchronisé', (tester) async {
    await _pump(
      tester,
      chargesState: StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: [_charge()],
      ),
      eligibility: EditiqueEligibilityStatus.blocked,
    );
    await tester.pumpAndSettle();

    expect(tester.widget<OutlinedButton>(_statementButton()).onPressed, isNull);
    expect(find.textContaining('pas encore synchronisé'), findsOneWidget);

    await tester.tap(_statementButton(), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Générer un relevé de compte ?'), findsNothing);
  });

  // Tant que la garde n'a pas tranché, on n'ouvre rien et on n'explique rien :
  // annoncer une raison qu'on ne connaît pas serait pire que de se taire.
  testWidgets('reste éteinte et muette pendant la résolution', (tester) async {
    await _pump(
      tester,
      chargesState: StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: [_charge()],
      ),
      eligibility: EditiqueEligibilityStatus.resolving,
    );
    await tester.pumpAndSettle();

    expect(tester.widget<OutlinedButton>(_statementButton()).onPressed, isNull);
    expect(find.textContaining('pas encore synchronisé'), findsNothing);
    expect(find.textContaining('Hors connexion'), findsNothing);
  });

  // B-2 (ADR-012) : le relevé est une émission serveur, elle n'a aucun sens
  // radio coupée.
  testWidgets('éteint l action hors ligne et l explique', (tester) async {
    await _pump(
      tester,
      chargesState: StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: [_charge()],
      ),
      syncStatus: SyncStatus.offline,
    );
    await tester.pumpAndSettle();

    expect(tester.widget<OutlinedButton>(_statementButton()).onPressed, isNull);
    expect(find.textContaining('Hors connexion'), findsOneWidget);
  });

  // Décision D-9 : `authRequired` reste ACTIF. Une émission en 401 est une
  // erreur traitée par l'anatomie d'erreur ; un grisage muet cacherait une
  // session à rouvrir.
  testWidgets('laisse l action active en session à ré-authentifier', (
    tester,
  ) async {
    await _pump(
      tester,
      chargesState: StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: [_charge()],
      ),
      syncStatus: SyncStatus.authRequired,
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<OutlinedButton>(_statementButton()).onPressed,
      isNotNull,
    );
  });

  // Ordre des messages : l'ineligibilité prime sur le hors-ligne, qui prime sur
  // l'absence de frais — on nomme la cause la plus fondamentale.
  testWidgets('nomme la synchro d abord quand tout est bloqué', (tester) async {
    await _pump(
      tester,
      chargesState: const StudentChargesState(
        status: StudentChargesStatus.success,
        studentCharges: [],
      ),
      eligibility: EditiqueEligibilityStatus.blocked,
      syncStatus: SyncStatus.offline,
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('pas encore synchronisé'), findsOneWidget);
    expect(find.textContaining('Hors connexion'), findsNothing);
    expect(find.textContaining('Aucun frais'), findsNothing);
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
