import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/usecases/emit_payment_receipt_use_case.dart';
import 'package:school_app_flutter/features/documents/presentation/bloc/editique_document_bloc.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/editique_document_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class MockEmitPaymentReceiptUseCase extends Mock
    implements EmitPaymentReceiptUseCase {}

/// Tailles réelles de la cible : tablette Android paysage, puis un téléphone
/// bas de gamme en paysage — les deux hauteurs où la modale est la plus serrée.
const _tabletLandscape = Size(1280, 800);
const _phoneLandscape = Size(720, 360);

Future<void> _pumpLoading(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final useCase = MockEmitPaymentReceiptUseCase();
  // Ne se résout jamais : fige l'état de chargement, celui qui affiche le
  // gabarit de page.
  when(
    () => useCase(any()),
  ).thenAnswer((_) => Completer<Either<Failure, EditiqueDocument>>().future);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<EditiqueDocumentBloc>(
          create: (_) =>
              EditiqueDocumentBloc(emitPaymentReceiptUseCase: useCase)
                ..add(const EditiquePaymentReceiptRequested(paymentId: 'p-1')),
          child: EditiqueDocumentDialogView(onRetry: (_) {}),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(
    () => registerFallbackValue(const EmitPaymentReceiptParams(paymentId: 'x')),
  );

  // Régression : le gabarit de page portait une hauteur fixe, si bien que sur
  // une tablette 1280×800 le corps dépassait de ~20 dp la place que lui laissent
  // l'en-tête et le pied.
  testWidgets('chargement : aucun débordement sur tablette paysage', (
    tester,
  ) async {
    await _pumpLoading(tester, size: _tabletLandscape);

    expect(tester.takeException(), isNull);
    expect(find.text('Préparation du document…'), findsOneWidget);
  });

  testWidgets('chargement : aucun débordement sur un écran très bas', (
    tester,
  ) async {
    await _pumpLoading(tester, size: _phoneLandscape);

    expect(tester.takeException(), isNull);
  });

  group('échec', () {
    testWidgets('rend l anatomie d erreur sans déborder', (tester) async {
      await _pumpFailure(
        tester,
        size: _tabletLandscape,
        failure: const NotFoundFailure(),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Document indisponible'), findsOneWidget);
    });

    testWidgets('ne déborde pas non plus sur un écran très bas', (
      tester,
    ) async {
      await _pumpFailure(
        tester,
        size: _phoneLandscape,
        failure: const ServerFailure(),
      );

      expect(tester.takeException(), isNull);
    });

    // Le reçu est archivé côté serveur, donc rejouable : même après une issue
    // inconnue, redemander re-sert les mêmes octets sous le même numéro.
    testWidgets('propose la reprise sur une issue inconnue (pièce archivée)', (
      tester,
    ) async {
      await _pumpFailure(
        tester,
        size: _tabletLandscape,
        failure: const UncertainOutcomeFailure(),
      );

      expect(find.text('Résultat indéterminé'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    testWidgets('ne propose jamais la reprise sur un accès refusé', (
      tester,
    ) async {
      await _pumpFailure(
        tester,
        size: _tabletLandscape,
        failure: const UnauthorizedFailure(),
      );

      expect(find.text('Accès refusé'), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
    });

    // Sans ce câblage la carte 401 n'offrait AUCUNE action : ni reconnexion
    // (callback absent), ni reprise (l'anatomie 401 la remplace par défaut).
    // L'utilisateur ne pouvait que refermer sans savoir quoi faire.
    testWidgets('session expirée : propose la reconnexion', (tester) async {
      var reconnected = false;
      await _pumpFailure(
        tester,
        size: _tabletLandscape,
        failure: const InvalidCredentialsFailure(),
        onReconnect: () => reconnected = true,
      );

      expect(find.text('Session expirée'), findsOneWidget);
      expect(find.text('Se reconnecter'), findsOneWidget);

      await tester.tap(find.text('Se reconnecter'));
      await tester.pump();
      expect(reconnected, isTrue);
    });

    testWidgets('session expirée sans callback : aucune action inventée', (
      tester,
    ) async {
      await _pumpFailure(
        tester,
        size: _tabletLandscape,
        failure: const InvalidCredentialsFailure(),
      );

      expect(find.text('Session expirée'), findsOneWidget);
      expect(find.text('Se reconnecter'), findsNothing);
    });

    testWidgets('la reprise relance bien une émission', (tester) async {
      final useCase = await _pumpFailure(
        tester,
        size: _tabletLandscape,
        failure: const ServerFailure(),
      );

      await tester.tap(find.text('Réessayer'));
      await tester.pump();

      verify(() => useCase(any())).called(2);
    });
  });
}

/// Monte la modale sur un échec donné et rend le mock, pour vérifier le rejeu.
Future<MockEmitPaymentReceiptUseCase> _pumpFailure(
  WidgetTester tester, {
  required Size size,
  required Failure failure,
  VoidCallback? onReconnect,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final useCase = MockEmitPaymentReceiptUseCase();
  when(() => useCase(any())).thenAnswer((_) async => Left(failure));

  late EditiqueDocumentBloc bloc;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<EditiqueDocumentBloc>(
          create: (_) {
            bloc = EditiqueDocumentBloc(emitPaymentReceiptUseCase: useCase);
            return bloc
              ..add(const EditiquePaymentReceiptRequested(paymentId: 'p-1'));
          },
          child: EditiqueDocumentDialogView(
            onRetry: (_) => bloc.add(
              const EditiquePaymentReceiptRequested(paymentId: 'p-1'),
            ),
            onReconnect: onReconnect,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return useCase;
}
