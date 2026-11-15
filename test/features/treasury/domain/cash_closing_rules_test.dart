import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_currency.dart';
import 'package:school_app_flutter/features/treasury/domain/services/cash_closing_rules.dart';

void main() {
  group('blockOf — la première raison est celle qu on montre', () {
    ClosingBlock? block({
      bool isToday = true,
      bool closed = false,
      bool canClose = true,
      bool online = true,
      int pendingSync = 0,
      int pendingAfter = 0,
    }) => CashClosingRules.blockOf(
      isToday: isToday,
      closed: closed,
      canClose: canClose,
      online: online,
      pendingSyncCount: pendingSync,
      pendingAfterClosureCount: pendingAfter,
    );

    test('tout est réuni : rien ne bloque', () => expect(block(), isNull));
    test('un jour passé', () {
      expect(block(isToday: false, online: false), ClosingBlock.notToday);
    });
    test(
      'déjà clôturée',
      () => expect(block(closed: true), ClosingBlock.closed),
    );
    test('sans le droit, avant le réseau', () {
      expect(block(canClose: false, online: false), ClosingBlock.noRight);
    });
    test('hors ligne, avant les envois en attente (D2)', () {
      expect(block(online: false, pendingSync: 3), ClosingBlock.offline);
    });
    test('des envois en attente', () {
      expect(block(pendingSync: 1, pendingAfter: 1), ClosingBlock.pendingSync);
    });
    test('des lignes arrivées après clôture sans réponse (R19)', () {
      expect(block(pendingAfter: 2), ClosingBlock.pendingAfterClosure);
    });
  });

  group('canSubmit (R9)', () {
    bool can(
      ClosingAnswer? answer, {
      int? declared,
      String justification = '',
      TreasuryCurrency currency = TreasuryCurrency.cdf,
    }) => CashClosingRules.canSubmit(
      answer: answer,
      currency: currency,
      shownExpectedInCents: 345000000,
      declaredInCents: declared,
      justification: justification,
    );

    test('sans réponse : non', () => expect(can(null), isFalse));
    test('« Oui » suffit', () => expect(can(ClosingAnswer.matches), isTrue));
    test('« Non » sans montant : non', () {
      expect(can(ClosingAnswer.differs, justification: 'Rendu'), isFalse);
    });
    test('« Non » égal au reste montré : non (choisir « Oui »)', () {
      expect(
        can(ClosingAnswer.differs, declared: 345000000, justification: 'abcde'),
        isFalse,
      );
    });
    test('« Non » avec une justification de 4 caractères : non ; 5 : oui', () {
      expect(
        can(
          ClosingAnswer.differs,
          declared: 344500000,
          justification: ' abcd ',
        ),
        isFalse,
      );
      expect(
        can(ClosingAnswer.differs, declared: 344500000, justification: 'abcde'),
        isTrue,
      );
    });
    test('« Non » à 0 : une caisse vide se déclare (D3)', () {
      expect(
        can(ClosingAnswer.differs, declared: 0, justification: 'Dépôt banque'),
        isTrue,
      );
    });
    test('« Non » avec des centimes de franc : non', () {
      expect(
        can(ClosingAnswer.differs, declared: 344500050, justification: 'abcde'),
        isFalse,
      );
    });
  });

  group('step — dimanche sauté, bornes (R4, R15)', () {
    final min = DateTime(2026, 10, 1);
    final today = DateTime(2026, 10, 22); // jeudi

    test('du lundi 19, en arrière : le samedi 17', () {
      expect(
        CashClosingRules.step(
          DateTime(2026, 10, 19),
          -1,
          min: min,
          today: today,
        ),
        DateTime(2026, 10, 17),
      );
    });
    test('du samedi 17, en avant : le lundi 19', () {
      expect(
        CashClosingRules.step(
          DateTime(2026, 10, 17),
          1,
          min: min,
          today: today,
        ),
        DateTime(2026, 10, 19),
      );
    });
    test('pas après aujourd hui', () {
      expect(CashClosingRules.step(today, 1, min: min, today: today), isNull);
    });
    test('pas avant le début de l historique', () {
      expect(CashClosingRules.step(min, -1, min: min, today: today), isNull);
    });
  });
}
