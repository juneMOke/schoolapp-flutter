import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/offline/sync_state.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_account_statement_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_enrollment_attestation_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_financial_clearance_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_note_perception_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_payment_receipt_use_case.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/documents_local_dossier_cubit.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_document_bloc.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_eligibility_cubit.dart';
import 'package:school_app_flutter/features/documents/presentation/context/documents_catalog_intent.dart';
import 'package:school_app_flutter/features/documents/presentation/pages/documents_catalog_page.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_enrollment_detail.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_generated_document.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_student.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/enrollment_offline_enums.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/get_local_enrollment_detail_use_case.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockGetLocalEnrollmentDetailUseCase extends Mock
    implements GetLocalEnrollmentDetailUseCase {}

class _MockEmitAccountStatementUseCase extends Mock
    implements EmitAccountStatementUseCase {}

class _MockEmitEnrollmentAttestationUseCase extends Mock
    implements EmitEnrollmentAttestationUseCase {}

class _MockEmitNotePerceptionUseCase extends Mock
    implements EmitNotePerceptionUseCase {}

class _MockEmitFinancialClearanceUseCase extends Mock
    implements EmitFinancialClearanceUseCase {}

class _MockEmitPaymentReceiptUseCase extends Mock
    implements EmitPaymentReceiptUseCase {}

/// Cubit d'éligibilité piloté par le test : le vrai lit la base locale.
class _FakeEligibilityCubit extends Cubit<EditiqueEligibilityState>
    implements EditiqueEligibilityCubit {
  _FakeEligibilityCubit(super.initialState);

  @override
  Future<void> resolveForStudent(String studentId) async {}
}

class _FakeSyncStatusCubit extends Cubit<SyncStatusState>
    implements SyncStatusCubit {
  _FakeSyncStatusCubit(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _intent = DocumentsCatalogIntent(
  studentId: 's-1',
  academicYearId: 'y-1',
  enrollmentId: 'e-1',
  firstName: 'Amina',
  lastName: 'Mbala',
  surname: 'Kasa',
  levelName: '5e primaire',
  levelGroupName: 'Primaire',
);

final _getIt = GetIt.instance;

Future<void> _pump(
  WidgetTester tester, {
  DocumentsCatalogIntent intent = _intent,
  EditiqueEligibilityStatus eligibility = EditiqueEligibilityStatus.eligible,
  SyncStatus syncStatus = SyncStatus.synced,
  Size size = const Size(1280, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  _getIt.registerFactory<EditiqueEligibilityCubit>(
    () => _FakeEligibilityCubit(EditiqueEligibilityState(status: eligibility)),
  );

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<SyncStatusCubit>(
        create: (_) =>
            _FakeSyncStatusCubit(SyncStatusState(status: syncStatus)),
        child: DocumentsCatalogPage(intent: intent),
      ),
    ),
  );
  await tester.pump();
}

LocalEnrollment _enrollment() => const LocalEnrollment(
  id: 'e-1',
  studentId: 's-1',
  enrollmentType: EnrollmentType.newEnrollment,
  status: OfflineEnrollmentStatus.completed,
  academicYearId: 'y-1',
  enrollmentDate: '2026-09-01',
  syncState: SyncState.synced,
);

LocalStudent _student() => const LocalStudent(
  id: 's-1',
  firstName: 'Amina',
  lastName: 'Mbala',
  gender: OfflineGender.female,
  dateOfBirth: '2014-02-01',
  syncState: SyncState.synced,
);

LocalGeneratedDocument _definitiveAttestation() => const LocalGeneratedDocument(
  id: 'doc-1',
  docDomain: 'ENROLLMENT',
  enrollmentId: 'e-1',
  docType: 'AI',
  number: 'ETL-AI-2526-000431',
  status: 'DEFINITIVE',
  createdAt: 1735689600000,
);

void main() {
  late _MockGetLocalEnrollmentDetailUseCase detailUseCase;

  setUpAll(() {
    registerFallbackValue(
      const EmitEnrollmentAttestationParams(enrollmentId: 'x'),
    );
  });

  setUp(() {
    detailUseCase = _MockGetLocalEnrollmentDetailUseCase();
    // Aucun dossier local lisible par défaut : l'attestation reste éteinte,
    // les autres pièces dépendent de la seule éligibilité.
    when(
      () => detailUseCase(any()),
    ).thenAnswer((_) async => const Left(NotFoundFailure()));

    _getIt.registerFactory<DocumentsLocalDossierCubit>(
      () => DocumentsLocalDossierCubit(detailUseCase),
    );
    _getIt.registerFactory<EditiqueDocumentBloc>(
      () => EditiqueDocumentBloc(
        emitEnrollmentAttestationUseCase:
            _MockEmitEnrollmentAttestationUseCase(),
        emitNotePerceptionUseCase: _MockEmitNotePerceptionUseCase(),
        emitPaymentReceiptUseCase: _MockEmitPaymentReceiptUseCase(),
        emitAccountStatementUseCase: _MockEmitAccountStatementUseCase(),
        emitFinancialClearanceUseCase: _MockEmitFinancialClearanceUseCase(),
      ),
    );
  });

  tearDown(() => _getIt.reset());

  testWidgets('affiche les deux groupes et les cinq pièces', (tester) async {
    await _pump(tester);

    expect(find.text('Scolarité'), findsOneWidget);
    expect(find.text('Finances'), findsOneWidget);
    expect(find.text("Attestation d'inscription"), findsOneWidget);
    expect(find.text('Note de perception'), findsOneWidget);
    expect(find.text('Reçu de paiement'), findsOneWidget);
    expect(find.text('Relevé de compte'), findsOneWidget);
    expect(find.text('Quitus financier'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('n affiche pas le groupe Académique ni le bulletin', (
    tester,
  ) async {
    await _pump(tester);

    expect(find.text('Académique'), findsNothing);
    expect(find.textContaining('Bulletin'), findsNothing);
  });

  testWidgets('marque la nature de chaque pièce', (tester) async {
    await _pump(tester);

    expect(find.text('Figé'), findsNWidgets(3));
    expect(find.text('Horodaté'), findsNWidgets(2));
  });

  // Le reçu se produit par VERSEMENT, à l'encaissement : le catalogue le montre
  // pour la complétude du dossier mais ne l'émet jamais.
  testWidgets('renvoie le reçu vers la Facturation', (tester) async {
    await _pump(tester);

    expect(find.textContaining('Un reçu par versement'), findsOneWidget);
  });

  // La garde qui évite un 404 : trois des quatre identifiants sont des uuid
  // CLIENT avant l'acquittement serveur.
  testWidgets('éteint les pièces d un élève non synchronisé', (tester) async {
    await _pump(tester, eligibility: EditiqueEligibilityStatus.blocked);

    expect(
      find.textContaining('Élève pas encore synchronisé'),
      findsNWidgets(3),
    );
  });

  // B-2 : relevé et quitus sont des émissions serveur.
  testWidgets('éteint et explique les pièces hors ligne', (tester) async {
    await _pump(tester, syncStatus: SyncStatus.offline);

    expect(find.textContaining('Hors connexion'), findsNWidgets(3));
  });

  // D-9 : `authRequired` reste actif — une émission en 401 est une erreur
  // traitée, alors qu'un grisage muet cacherait une session à rouvrir.
  testWidgets('laisse les pièces actives en session à ré-authentifier', (
    tester,
  ) async {
    await _pump(tester, syncStatus: SyncStatus.authRequired);

    expect(find.textContaining('Hors connexion'), findsNothing);
    expect(find.text('Générer maintenant'), findsNWidgets(2));
  });

  testWidgets('signale l absence de référence de dossier en lien profond', (
    tester,
  ) async {
    await _pump(
      tester,
      intent: const DocumentsCatalogIntent(
        studentId: 's-1',
        academicYearId: 'y-1',
      ),
    );

    expect(find.textContaining('Dossier introuvable'), findsOneWidget);
  });

  // Chaque émission d'une pièce horodatée brûle un numéro de séquence : l'appui
  // ouvre une confirmation, jamais directement la génération.
  testWidgets('demande confirmation avant de générer un relevé', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Générer maintenant').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Générer :'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
  });

  // Le quitus porte un avertissement supplémentaire : le serveur l'émet quel
  // que soit le solde, avec la mention « NON EN RÈGLE ».
  testWidgets('avertit avant de générer un quitus non en règle', (
    tester,
  ) async {
    await _pump(tester);

    await tester.tap(find.text('Générer maintenant').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('NON EN RÈGLE'), findsOneWidget);
  });

  testWidgets('affiche la dernière émission connue localement', (tester) async {
    when(() => detailUseCase(any())).thenAnswer(
      (_) async => Right(
        LocalEnrollmentDetail(
          enrollment: _enrollment(),
          student: _student(),
          documents: [_definitiveAttestation()],
        ),
      ),
    );

    await _pump(tester);
    await tester.pump();

    expect(find.textContaining('ETL-AI-2526-000431'), findsOneWidget);
    expect(find.text('Consulter'), findsOneWidget);
  });

  testWidgets('reste lisible en largeur compacte', (tester) async {
    await _pump(tester, size: const Size(720, 1200));

    expect(tester.takeException(), isNull);
    expect(find.text("Attestation d'inscription"), findsOneWidget);
  });
}
