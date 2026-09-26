import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/finance/presentation/helpers/payment_correction_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations_fr.dart';

/// Le récit d'une annulation serveur (B5), tel que la fiche l'écrit.
void main() {
  final l10n = AppLocalizationsFr();

  test('date, auteur, motif et précision', () {
    expect(
      paymentServerCancellationNotice(
        date: '26 sept. 2026',
        byName: 'Moke Junior',
        reasonCode: 'WRONG_AMOUNT',
        reason: 'Saisi 150 \$ au lieu de 50 \$',
        l10n: l10n,
      ),
      'Versement annulé le 26 sept. 2026 par Moke Junior. '
      'Motif : Mauvais montant — Saisi 150 \$ au lieu de 50 \$',
    );
  });

  // Les deux routes en ligne existantes n'ont pas de code de motif.
  test('sans auteur ni motif, la date seule', () {
    expect(
      paymentServerCancellationNotice(
        date: '26 sept. 2026',
        byName: null,
        reasonCode: null,
        reason: null,
        l10n: l10n,
      ),
      'Versement annulé le 26 sept. 2026.',
    );
  });

  test('un code inconnu se dit tel quel, plutôt que de disparaître', () {
    expect(
      paymentServerCancellationNotice(
        date: '26 sept. 2026',
        byName: null,
        reasonCode: 'FUTURE_CODE',
        reason: null,
        l10n: l10n,
      ),
      endsWith('Motif : FUTURE_CODE'),
    );
  });

  test('sans date, rien', () {
    expect(
      paymentServerCancellationNotice(
        date: null,
        byName: 'X',
        reasonCode: null,
        reason: null,
        l10n: l10n,
      ),
      isNull,
    );
  });
}
