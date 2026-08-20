import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_eligibility_cubit.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/finance_offline_state.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_freshness_cubit.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/ledger_revalidation_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/payments_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/student_charges_bloc.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';
import 'package:school_app_flutter/features/finance/presentation/pages/facturation_detail_page.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/finance_context_error_card.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_charges_section.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/facturation_detail_payments_section.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les deux faux BLoCs implémentent `add` explicitement : le chargeur en émet
/// dès le premier post-frame, et c'est justement ce qu'on veut voir arriver —
/// une fiche qui reste sur la carte de contexte n'émet rien du tout.
class _FakePaymentsBloc extends Cubit<PaymentsState> implements PaymentsBloc {
  _FakePaymentsBloc() : super(const PaymentsState());

  @override
  void add(PaymentsEvent event) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeStudentChargesBloc extends Cubit<StudentChargesState>
    implements StudentChargesBloc {
  _FakeStudentChargesBloc() : super(const StudentChargesState());

  @override
  void add(StudentChargesEvent event) {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Le chemin d'écriture n'est pas exercé ici, mais il est enregistré : un
/// `BlocProvider` paresseux ne le résout que si quelqu'un le lit, et une fiche
/// qui se met à le lire au montage doit échouer sur une assertion de test, pas
/// sur un GetIt vide.
class _FakeFinanceOfflineBloc extends Cubit<FinanceOfflineState>
    implements FinanceOfflineBloc {
  _FakeFinanceOfflineBloc() : super(const FinanceOfflineInitial());

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLedgerFreshnessCubit extends Cubit<int?>
    implements LedgerFreshnessCubit {
  _FakeLedgerFreshnessCubit() : super(null);

  @override
  Future<void> load(String studentId) async {}
}

class _FakeLedgerRevalidationCubit extends Cubit<int>
    implements LedgerRevalidationCubit {
  _FakeLedgerRevalidationCubit() : super(0);

  @override
  void watch(String studentId) {}
}

/// La barre de relevé lit l'état de synchro pour dire ce qu'elle offre : sans
/// lui dans l'arbre, la page ne se peint pas du tout.
class _FakeSyncStatusCubit extends Cubit<SyncStatusState>
    implements SyncStatusCubit {
  _FakeSyncStatusCubit()
    : super(const SyncStatusState(status: SyncStatus.synced));

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEditiqueEligibilityCubit extends Cubit<EditiqueEligibilityState>
    implements EditiqueEligibilityCubit {
  _FakeEditiqueEligibilityCubit() : super(const EditiqueEligibilityState());

  @override
  Future<void> resolveForStudent(String studentId) async {}
}

/// Recherche **par identité** en Facturation : le formulaire bi-mode n'exige
/// alors aucun niveau, donc `lastSummariesQuery.schoolLevelId` est vide, donc la
/// page de liste ne trouve aucun nom de classe à mettre dans l'intent. La classe
/// est du **contexte d'affichage** — jamais une condition d'ouverture : le
/// grand-livre ne dépend que de l'élève et de l'année.
FacturationDetailIntent _intentSansClasse() => const FacturationDetailIntent(
  studentId: 's-1',
  academicYearId: 'y-1',
  firstName: 'Daniel',
  lastName: 'Kabongo',
  surname: 'Mwamba',
  levelName: '',
  levelGroupName: '',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async => getIt.reset());

  Future<void> pump(WidgetTester tester, FacturationDetailIntent intent) async {
    tester.view.physicalSize = const Size(1400, 1800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BlocProvider<SyncStatusCubit>(
          create: (_) => _FakeSyncStatusCubit(),
          child: FacturationDetailPage(intent: intent),
        ),
      ),
    );
    await tester.pump();
  }

  setUp(() {
    getIt.registerFactory<PaymentsBloc>(_FakePaymentsBloc.new);
    getIt.registerFactory<StudentChargesBloc>(_FakeStudentChargesBloc.new);
    getIt.registerFactory<FinanceOfflineBloc>(_FakeFinanceOfflineBloc.new);
    getIt.registerFactory<LedgerFreshnessCubit>(_FakeLedgerFreshnessCubit.new);
    getIt.registerFactory<LedgerRevalidationCubit>(
      _FakeLedgerRevalidationCubit.new,
    );
    getIt.registerFactory<EditiqueEligibilityCubit>(
      _FakeEditiqueEligibilityCubit.new,
    );
  });

  testWidgets('une fiche ouverte depuis une recherche par identité affiche le '
      'grand-livre', (tester) async {
    await pump(tester, _intentSansClasse());

    expect(
      find.byType(FinanceContextErrorCard),
      findsNothing,
      reason:
          'on sait de QUI il s\'agit : une classe manquante n\'est pas un '
          'motif de refuser la fiche',
    );
    expect(find.byType(FacturationDetailPaymentsSection), findsOneWidget);
    expect(find.byType(FacturationDetailChargesSection), findsOneWidget);
  });

  testWidgets(
    'CONTRE-ÉPREUVE : sans identité du tout, la carte de contexte reste',
    (tester) async {
      // Lien profond ouvert sans `extra` : on ne sait pas de qui est cet argent.
      await pump(
        tester,
        const FacturationDetailIntent.invalid(
          studentId: 's-1',
          academicYearId: 'y-1',
        ),
      );

      expect(find.byType(FinanceContextErrorCard), findsOneWidget);
      expect(find.byType(FacturationDetailPaymentsSection), findsNothing);
    },
  );
}
