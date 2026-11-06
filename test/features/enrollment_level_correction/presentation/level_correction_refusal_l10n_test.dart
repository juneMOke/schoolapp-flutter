import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/domain/entities/level_correction_refusal.dart';
import 'package:school_app_flutter/features/enrollment_level_correction/presentation/widgets/level_correction_refusal_l10n.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

void main() {
  // Les codes du contrat, recopiés à la main : un renommage de valeur sur le
  // fil doit faire tomber ce test, pas passer inaperçu.
  const contractCodes = [
    'ENROLLMENT_NOT_CONFIRMED',
    'STALE_LEVEL',
    'INVALID_TARGET_LEVEL',
    'NO_TARIFF_FOR_LEVEL',
    'LEVEL_CORRECTION_HAS_PAYMENTS',
    'LEVEL_CORRECTION_HAS_GRADES',
    'TARGET_CLASSROOM_REQUIRED',
    'LEVEL_MISMATCH',
  ];

  test('chaque code 422 du contrat est connu, et rien de plus', () {
    expect(
      LevelCorrectionRefusal.values.map((r) => r.wire),
      unorderedEquals(contractCodes),
    );
  });

  test("le 409 d'attente n'est pas un refus", () {
    expect(
      LevelCorrectionRefusal.fromWire('ENROLLMENT_NOT_YET_SYNCED'),
      isNull,
    );
  });

  for (final locale in AppLocalizations.supportedLocales) {
    group('messages (${locale.languageCode})', () {
      final l10n = lookupAppLocalizations(locale);

      test('chaque code a sa phrase propre, distincte de la générique', () {
        final messages = contractCodes
            .map(l10n.levelCorrectionRefusalMessage)
            .toList();
        expect(messages, isNot(contains(l10n.levelCorrectionRefusedGeneric)));
        expect(messages.toSet(), hasLength(contractCodes.length));
      });

      test('un code inconnu ou un statut HTTP retombe sur la générique', () {
        for (final code in [null, '', '403', 'SOMETHING_NEW']) {
          expect(
            l10n.levelCorrectionRefusalMessage(code),
            l10n.levelCorrectionRefusedGeneric,
          );
        }
      });

      test('le code brut ne fuit jamais dans la phrase', () {
        for (final code in contractCodes) {
          expect(
            l10n.levelCorrectionRefusalMessage(code),
            isNot(contains(code)),
          );
        }
      });
    });
  }

  test('les locales couvertes sont bien FR et EN', () {
    expect(
      AppLocalizations.supportedLocales,
      containsAll(const [Locale('fr'), Locale('en')]),
    );
  });
}
