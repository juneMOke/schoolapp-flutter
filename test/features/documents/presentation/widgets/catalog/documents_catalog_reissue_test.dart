import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document.dart';
import 'package:school_app_flutter/features/documents/domain/entities/editique_document_type.dart';
import 'package:school_app_flutter/features/documents/presentation/widgets/catalog/documents_catalog_reissue.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

Widget _harness(Widget child, {required List<String> permissions}) {
  final auth = _MockAuthBloc();
  final state = AuthState(
    status: AuthStatus.authenticated,
    permissions: permissions,
  );
  when(() => auth.state).thenReturn(state);
  whenListen(auth, Stream<AuthState>.value(state), initialState: state);
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('fr'),
    home: Scaffold(
      body: BlocProvider<AuthBloc>.value(
        value: auth,
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  );
}

EditiqueDocument _returned({
  String? documentId = 'doc-2',
  String? emittedOn,
  bool wasReplayed = false,
}) => EditiqueDocument(
  type: EditiqueDocumentType.enrollmentAttestation,
  bytes: Uint8List(4),
  fileName: 'piece.pdf',
  documentId: documentId,
  emittedOn: emittedOn,
  wasReplayed: wasReplayed,
);

void main() {
  group('isPriorReplacement', () {
    const today = '2026-11-08';

    test('composée aujourd\'hui : neuve', () {
      expect(
        isPriorReplacement(
          _returned(emittedOn: today),
          sentDocumentId: 'doc-1',
          today: today,
        ),
        isFalse,
      );
    });

    test('émise un jour antérieur : déjà là, rendue telle quelle', () {
      expect(
        isPriorReplacement(
          _returned(emittedOn: '2026-11-07'),
          sentDocumentId: 'doc-1',
          today: today,
        ),
        isTrue,
      );
    });

    test('la pièce envoyée elle-même : rien n\'a été remplacé', () {
      expect(
        isPriorReplacement(
          _returned(documentId: 'doc-1', emittedOn: today),
          sentDocumentId: 'doc-1',
          today: today,
        ),
        isTrue,
      );
    });

    test('rejeu signalé le jour même : le serveur fait foi', () {
      expect(
        isPriorReplacement(
          _returned(emittedOn: today, wasReplayed: true),
          sentDocumentId: 'doc-1',
          today: today,
        ),
        isTrue,
      );
    });

    test('jour inconnu : on ne prétend rien', () {
      expect(
        isPriorReplacement(_returned(), sentDocumentId: 'doc-1', today: today),
        isFalse,
      );
    });
  });

  group('DocumentsCatalogReissueButton', () {
    testWidgets('sans editique.cancel : ni bouton, ni blanc à sa place', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          DocumentsCatalogReissueButton(
            busy: false,
            gap: true,
            onPressed: () {},
          ),
          permissions: const ['editique.read'],
        ),
      );

      expect(find.byType(OutlinedButton), findsNothing);
      expect(
        tester.getSize(find.byType(DocumentsCatalogReissueButton)),
        Size.zero,
      );
    });

    testWidgets('pendant une demande, le bouton est inerte', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _harness(
          DocumentsCatalogReissueButton(busy: true, onPressed: () => taps++),
          permissions: const ['editique.cancel'],
        ),
      );

      await tester.tap(find.text('Réémettre corrigée'), warnIfMissed: false);
      expect(taps, 0);
    });
  });
}
