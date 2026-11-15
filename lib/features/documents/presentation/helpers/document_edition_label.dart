import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ajoute à [label], le libellé qui désigne une pièce, son édition dès la
/// deuxième : « Pièce n° ETL-AI-2526-000087 · édition 2 ».
///
/// Une attestation, une note de perception ou une fiche réémise garde son
/// numéro (back v0.17.0) : seule l'édition dit laquelle circule. La première ne
/// s'annonce pas — c'est l'état de toute pièce jamais réémise —, pas plus
/// qu'une édition inconnue (`null`), celle d'une pièce scellée avant que le
/// serveur ne l'annonce.
String withDocumentEdition(AppLocalizations l10n, String label, int? edition) =>
    (edition == null || edition < 2)
    ? label
    : '$label · ${l10n.documentsCurrentEdition(edition)}';
