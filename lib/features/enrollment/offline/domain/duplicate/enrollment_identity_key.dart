import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';

/// Clé de rapprochement d'un **nom**, pour la sonde de doublon d'inscription.
///
/// [SearchNormalizationHelper.normalize] plie déjà la casse et les accents. Il
/// ne plie pas les **séparateurs** — et c'est précisément là que le guichet
/// varie : « Kabeya-Mukendi » un jour, « Kabeya Mukendi » le lendemain,
/// « N'Guessan » avec l'apostrophe droite ou courbe selon le clavier. Trois
/// écritures du même nom, trois clés différentes, donc trois doublons manqués.
///
/// La clé n'est **jamais affichée** : elle ne sert qu'à comparer. Ce qui se
/// montre à l'écran reste la saisie telle qu'elle a été faite.
class EnrollmentIdentityKey {
  const EnrollmentIdentityKey._();

  /// Séparateurs internes d'un nom composé, repliés sur l'espace. Le tiret et
  /// les deux apostrophes suffisent : ce sont les seuls qu'un nom porte
  /// légitimement ici.
  static final RegExp _separators = RegExp(r"[-'’]");

  /// Suites d'espaces — `\s` couvre aussi l'insécable, qu'un copier-coller
  /// depuis un tableur laisse traîner sans que personne ne le voie.
  static final RegExp _spaces = RegExp(r'\s+');

  /// Clé comparable de [raw]. Chaîne vide pour une valeur absente ou blanche —
  /// un nom vide ne rapproche de personne, il est écarté par l'appelant.
  static String of(String? raw) {
    final normalized = SearchNormalizationHelper.normalize(raw ?? '');
    return normalized
        .replaceAll(_separators, ' ')
        .replaceAll(_spaces, ' ')
        .trim();
  }
}
