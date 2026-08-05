import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_account_statement_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_enrollment_attestation_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_financial_clearance_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_note_perception_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_payment_receipt_use_case.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/restitute_document_use_case.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_document_bloc.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/editique_document_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockEmitPaymentReceiptUseCase extends Mock
    implements EmitPaymentReceiptUseCase {}

class _MockEmitAccountStatementUseCase extends Mock
    implements EmitAccountStatementUseCase {}

class _MockEmitEnrollmentAttestationUseCase extends Mock
    implements EmitEnrollmentAttestationUseCase {}

class _MockEmitNotePerceptionUseCase extends Mock
    implements EmitNotePerceptionUseCase {}

class _MockEmitFinancialClearanceUseCase extends Mock
    implements EmitFinancialClearanceUseCase {}

class MockRestituteDocumentUseCase extends Mock
    implements RestituteDocumentUseCase {}

void main() {
  late _MockEmitPaymentReceiptUseCase receiptUseCase;

  setUpAll(
    () => registerFallbackValue(const EmitPaymentReceiptParams(paymentId: 'x')),
  );

  setUp(() {
    receiptUseCase = _MockEmitPaymentReceiptUseCase();
    // L'issue importe peu ici — le test porte sur le cycle de vie du BLoC —
    // mais elle doit ARRIVER. `Bloc.close()` attend ses émetteurs en vol : une
    // émission suspendue sur une `Completer` jamais complétée bloquerait le
    // `tearDown`, pas le corps du test, et le symptôme serait un délai de 10
    // minutes sans aucune trace exploitable.
    when(
      () => receiptUseCase(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
  });

  EditiqueDocumentBloc buildBloc() => EditiqueDocumentBloc(
    emitEnrollmentAttestationUseCase: _MockEmitEnrollmentAttestationUseCase(),
    emitNotePerceptionUseCase: _MockEmitNotePerceptionUseCase(),
    emitPaymentReceiptUseCase: receiptUseCase,
    emitAccountStatementUseCase: _MockEmitAccountStatementUseCase(),
    emitFinancialClearanceUseCase: _MockEmitFinancialClearanceUseCase(),
    restituteDocumentUseCase: MockRestituteDocumentUseCase(),
  );

  Future<void> pumpOpener(
    WidgetTester tester,
    EditiqueDocumentBloc bloc,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showEditiquePaymentReceiptDialog(
                context,
                paymentId: 'p-1',
                bloc: bloc,
              ),
              child: const Text('ouvrir'),
            ),
          ),
        ),
      ),
    );
  }

  // Invariant de propriété : un BLoC confié par un écran lui appartient. Le
  // fermer à la sortie de la modale couperait la ligne du catalogue qui
  // l'observe encore — l'écran afficherait une pièce figée sur un BLoC mort.
  testWidgets('ne ferme pas un BLoC confié par l appelant', (tester) async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    await pumpOpener(tester, bloc);
    await tester.tap(find.text('ouvrir'));
    // Pompage BORNÉ, jamais `pumpAndSettle` : le gabarit de chargement anime en
    // boucle tant que l'émission est en vol, donc l'arbre ne se stabilise
    // jamais et `pumpAndSettle` expirerait au bout de 10 minutes.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(bloc.isClosed, isFalse);

    // Ferme la modale et laisse la transition de sortie s'achever, pour que
    // `dispose` ait réellement tourné au moment de l'assertion.
    Navigator.of(tester.element(find.text('ouvrir'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(bloc.isClosed, isFalse);
  });

  // L'émission part une fois à l'ouverture, et une seule : poster l'événement
  // depuis un `build` le relancerait à chaque reconstruction du sous-arbre, et
  // un second envoi brûlerait un second numéro de séquence sur une pièce non
  // archivée.
  //
  // Le test PROVOQUE une reconstruction réelle et le VÉRIFIE. Pomper des images
  // ne suffit pas : sans invalidation, l'arbre du dialogue n'est pas reconstruit
  // et l'assertion passerait quelle que soit l'implémentation. On change donc la
  // taille de la vue — un `MediaQuery` dont la hauteur pilote la contrainte de
  // la modale — et on contrôle que cette contrainte a bougé avant de conclure.
  testWidgets('ne déclenche l émission qu une seule fois, même reconstruit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final bloc = buildBloc();
    addTearDown(bloc.close);

    await pumpOpener(tester, bloc);
    await tester.tap(find.text('ouvrir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // La modale se plafonne à 88 % de la hauteur d'écran : c'est la SEULE
    // contrainte finie de son sous-arbre, et elle suit donc le MediaQuery.
    // `Dialog` en insère d'autres, non bornées — d'où la sélection explicite.
    double dialogMaxHeight() => tester
        .widgetList<ConstrainedBox>(
          find.descendant(
            of: find.byType(EditiqueDocumentDialogView),
            matching: find.byType(ConstrainedBox),
          ),
        )
        .map((box) => box.constraints.maxHeight)
        .firstWhere((height) => height.isFinite);

    final before = dialogMaxHeight();

    // Invalide le MediaQuery : tout le sous-arbre du dialogue est reconstruit.
    tester.view.physicalSize = const Size(1280, 600);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Garde-fou du test lui-même : sans reconstruction avérée, il ne prouverait
    // rien.
    expect(
      dialogMaxHeight(),
      isNot(before),
      reason: 'le sous-arbre du dialogue n a pas été reconstruit',
    );

    verify(() => receiptUseCase(any())).called(1);
  });
}
