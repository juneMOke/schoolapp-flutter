import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/fee_control_notify_content.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/relance/fee_control_notify_dialog.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// O4 · Relance des parents : la sur-couche, rendue par le vrai thème (un
/// `FilledButton` y a une largeur minimale infinie, cf. la feuille d'appel).
const _message =
    'Cher parent, les frais Minerval · 6e A ne sont pas soldés pour votre '
    'enfant.';

const _recipients = [
  FeeControlNotifyRecipient(
    studentId: 's1',
    studentName: 'MOKE Junior',
    parentName: 'MOKE Albert',
    phoneNumber: '+243810000001',
  ),
  FeeControlNotifyRecipient(
    studentId: 's2',
    studentName: 'ILUNGA Grâce',
    parentName: 'ILUNGA Marie',
    phoneNumber: '+243820000002',
  ),
  FeeControlNotifyRecipient(studentId: 's3', studentName: 'KABONGO Paul'),
];

void main() {
  late List<String> sent;
  late FeeControlNotifySend onSend;
  bool? result;

  setUp(() {
    sent = [];
    result = null;
    onSend = (message) async => sent.add(message);
  });

  Future<void> pumpDialog(
    WidgetTester tester, {
    double width = 1280,
    double height = 900,
    double textScale = 1,
    List<FeeControlNotifyRecipient> recipients = _recipients,
  }) async {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('fr'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await FeeControlNotifyDialog.show(
                  context,
                  FeeControlNotifyDialog(
                    contextLabel: 'Minerval · 6e A',
                    initialMessage: _message,
                    recipients: recipients,
                    onSend: (message) => onSend(message),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('sur-titre, titre au compte des parents, contexte', (
    tester,
  ) async {
    await pumpDialog(tester);
    expect(find.text('RELANCE'), findsOneWidget);
    expect(find.text('Notifier 3 parents'), findsOneWidget);
    expect(find.text('Minerval · 6e A'), findsOneWidget);
    expect(find.text('Annuler'), findsOneWidget);
    expect(find.text('Envoyer'), findsOneWidget);
  });

  testWidgets('un seul parent : le singulier', (tester) async {
    await pumpDialog(tester, recipients: [_recipients.first]);
    expect(find.text('Notifier 1 parent'), findsOneWidget);
    expect(find.textContaining('Sans téléphone'), findsNothing);
  });

  testWidgets('message prérempli, modifiable, avec son compte', (tester) async {
    await pumpDialog(tester);
    expect(find.text(_message), findsOneWidget);
    expect(find.text('${_message.length} caractères'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Bonjour');
    await tester.pump();
    expect(find.text('7 caractères'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('fee-control-notify-send')));
    await tester.pumpAndSettle();
    // Le texte relu est celui qui part — corrigé compris.
    expect(sent, ['Bonjour']);
    expect(result, isTrue);
    expect(find.text('Notifier 3 parents'), findsNothing);
  });

  testWidgets('destinataires, puis ceux sans téléphone listés à part', (
    tester,
  ) async {
    await pumpDialog(tester);
    expect(find.text('DESTINATAIRES'), findsOneWidget);
    expect(find.text('MOKE Albert'), findsOneWidget);
    expect(find.text('+243810000001 · pour MOKE Junior'), findsOneWidget);
    expect(find.text('ILUNGA Marie'), findsOneWidget);
    expect(find.text('SANS TÉLÉPHONE CONNU (1)'), findsOneWidget);
    expect(find.text('Parent non renseigné'), findsOneWidget);
    expect(find.text('pour KABONGO Paul'), findsOneWidget);
  });

  testWidgets('« Envoi… », bouton inactif, un double toucher = un envoi', (
    tester,
  ) async {
    final gate = Completer<void>();
    var calls = 0;
    onSend = (_) {
      calls++;
      return gate.future;
    };
    await pumpDialog(tester);

    final send = find.byKey(const ValueKey('fee-control-notify-send'));
    await tester.tap(send);
    await tester.pump();
    expect(find.text('Envoi…'), findsOneWidget);
    await tester.tap(send, warnIfMissed: false);
    await tester.pump();
    expect(calls, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('échec : message dans la sur-couche, texte gardé', (
    tester,
  ) async {
    onSend = (_) async => throw StateError('share refused');
    await pumpDialog(tester);

    await tester.enterText(find.byType(TextField), 'Texte relu');
    await tester.tap(find.byKey(const ValueKey('fee-control-notify-send')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Le partage n\'a pas abouti. Votre message est conservé : réessayez.',
      ),
      findsOneWidget,
    );
    expect(find.text('Texte relu'), findsOneWidget);
    expect(find.text('Envoyer'), findsOneWidget);
    expect(result, isNull);
  });

  for (final (width, height) in [(360.0, 740.0), (1280.0, 800.0)]) {
    for (final scale in [1.0, 1.3]) {
      testWidgets('rendu à $width dp, texte ×$scale', (tester) async {
        await pumpDialog(
          tester,
          width: width,
          height: height,
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Envoyer'), findsOneWidget);
        // Sous 760 de fenêtre, la sur-couche prend tout l'écran (A11).
        expect(
          find.byWidgetPredicate(
            (w) => w is Dialog && w.insetPadding == EdgeInsets.zero,
          ),
          width < 760 ? findsOneWidget : findsNothing,
        );
      });
    }
  }

  group('message prérempli', () {
    late AppLocalizations l10n;

    setUpAll(() async {
      l10n = await AppLocalizations.delegate.load(const Locale('fr'));
    });

    test('échéance à J+7, jj/mm/aaaa, école nommée', () {
      expect(
        composeNotifyMessage(
          l10n,
          context: 'Minerval · 6e A',
          schoolName: 'CS La Colombe',
          today: DateTime(2026, 11, 28),
        ),
        'Cher parent, les frais Minerval · 6e A ne sont pas soldés pour '
        'votre enfant. Merci de passer à la caisse de l\'école avant le '
        '05/12/2026. La direction de CS La Colombe.',
      );
    });

    test('école inconnue : « la direction de l\'école »', () {
      expect(
        composeNotifyMessage(
          l10n,
          context: 'Minerval',
          schoolName: ' ',
          today: DateTime(2026, 1, 1),
        ),
        endsWith('avant le 08/01/2026. La direction de l\'école.'),
      );
    });
  });
}
