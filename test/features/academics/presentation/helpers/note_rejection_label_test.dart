import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Motif du rejet d'une note synchronisée (`NoteLineOutcome.reason`).
///
/// Le back v0.17.0 rend un refus de validation sous un code stable ; jusqu'à
/// la v0.16, c'était `INVALID: <phrase>`. Une ligne rangée avant la mise à jour
/// garde l'ancienne forme, d'où le repli par préfixe.
void main() {
  final l10n = lookupAppLocalizations(const Locale('fr'));

  test('chaque code de validation a son message', () {
    expect(
      noteRejectionLabel(l10n, 'INVALID_NOTE_POINTS_MISSING'),
      'Points manquants',
    );
    expect(
      noteRejectionLabel(l10n, 'INVALID_NOTE_POINTS_OUT_OF_RANGE'),
      'Points hors barème',
    );
    expect(
      noteRejectionLabel(l10n, 'INVALID_NOTE_COMMENT_TOO_LONG'),
      'Commentaire trop long',
    );
  });

  test('l ancienne forme et un code de validation inconnu restent lus', () {
    expect(noteRejectionLabel(l10n, 'INVALID: hors bornes'), 'Note invalide');
    expect(noteRejectionLabel(l10n, 'INVALID_NOTE_NOUVEAU'), 'Note invalide');
  });

  test('les autres motifs ne changent pas', () {
    expect(noteRejectionLabel(l10n, 'PERIODE_CLOSE'), 'Période close');
    expect(
      noteRejectionLabel(l10n, 'UNKNOWN_EVALUATION'),
      'Évaluation inconnue du serveur',
    );
    expect(
      noteRejectionLabel(l10n, 'EVALUATION_CONTEXT_UNAVAILABLE'),
      'Contexte indisponible',
    );
    expect(noteRejectionLabel(l10n, 'AUTRE'), 'Rejetée par le serveur');
  });
}
