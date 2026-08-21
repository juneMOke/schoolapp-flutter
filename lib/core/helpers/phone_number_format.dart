/// Format E.164 des numéros de téléphone saisis dans l'application.
///
/// Un numéro voyage TOUJOURS en E.164 (`+243816939060`) : c'est la valeur
/// portée par le `TextEditingController` d'un [EteeloPhoneInput], stockée en
/// base locale et envoyée au backend. Seule la partie NATIONALE
/// (`816939060`) est visible dans le champ de saisie, l'indicatif étant
/// affiché à côté dans une case dédiée.
///
/// Les fiches historiques ont pu être saisies dans des formats libres
/// (`0816939060`, `+243 81 693 90 60`, `00243816939060`) : [nationalPartOf]
/// les ramène toutes à la même partie nationale, ce qui permet de les
/// afficher correctement sans jamais réécrire la valeur stockée.
library;

/// Un indicatif pays proposé par le sélecteur.
///
/// V1 : un seul pays ([congoDrc]), non modifiable dans l'UI. La liste
/// [supported] existe pour que l'ouverture à d'autres pays ne touche pas au
/// composant de saisie.
class PhoneCountry {
  /// Code ISO 3166-1 alpha-2 (`CD`), utilisé comme identité stable.
  final String isoCode;

  /// Indicatif international, signe `+` inclus (`+243`).
  final String dialCode;

  /// Drapeau en emoji régional. Peut ne pas être rendu par toutes les
  /// plateformes : l'indicatif reste donc toujours affiché à côté.
  final String flagEmoji;

  /// Nombre de chiffres attendus dans la partie nationale (RDC : 9).
  final int nationalLength;

  /// Exemple affiché en placeholder du champ (`816939060`).
  final String exampleNationalNumber;

  const PhoneCountry({
    required this.isoCode,
    required this.dialCode,
    required this.flagEmoji,
    required this.nationalLength,
    required this.exampleNationalNumber,
  });

  /// République démocratique du Congo — pays par défaut de l'application.
  static const congoDrc = PhoneCountry(
    isoCode: 'CD',
    dialCode: '+243',
    flagEmoji: '🇨🇩',
    nationalLength: 9,
    exampleNationalNumber: '816939060',
  );

  /// Indicatifs sélectionnables. V1 : un seul.
  static const supported = <PhoneCountry>[congoDrc];
}

/// Conversions entre la saisie utilisateur et le format E.164.
abstract final class PhoneNumberFormat {
  /// Chiffres d'une saisie, séparateurs et `+` retirés.
  static String digitsOnly(String raw) => raw.replaceAll(RegExp(r'\D'), '');

  /// Partie nationale d'une valeur brute, quel que soit son format d'origine.
  ///
  /// Retire, dans cet ordre, le préfixe international (`+243`, `00243` ou
  /// `243`) puis le `0` de départ du plan national. Une valeur illisible
  /// ressort telle quelle (chiffres seuls) : à l'appelant de la signaler
  /// invalide plutôt que de la tronquer.
  ///
  /// Une saisie NUE, sans `+`, n'est amputée de l'indicatif que si elle est
  /// déjà trop longue pour un numéro national : sinon un numéro qui
  /// commencerait par les mêmes chiffres que l'indicatif serait mutilé. Un
  /// `+` explicite lève le doute, y compris sur un numéro incomplet
  /// (`+2438169` → `8169`, cas d'une recherche par bribe).
  static String nationalPartOf(
    String raw, {
    PhoneCountry country = PhoneCountry.congoDrc,
  }) {
    final hasExplicitPlus = raw.trimLeft().startsWith('+');
    var digits = digitsOnly(raw);
    if (digits.isEmpty) return '';

    final dial = digitsOnly(country.dialCode);
    if (digits.startsWith('00$dial')) {
      digits = digits.substring(2 + dial.length);
    } else if (digits.startsWith(dial) &&
        (hasExplicitPlus || digits.length > country.nationalLength)) {
      digits = digits.substring(dial.length);
    }

    if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  /// E.164 correspondant à une partie nationale saisie. Chaîne vide si la
  /// saisie ne porte aucun chiffre : un champ vide ne doit jamais produire un
  /// indicatif orphelin (`+243`).
  static String toE164(
    String nationalPart, {
    PhoneCountry country = PhoneCountry.congoDrc,
  }) {
    final digits = digitsOnly(nationalPart);
    if (digits.isEmpty) return '';
    return '${country.dialCode}$digits';
  }

  /// Normalise une valeur brute quelconque en E.164.
  static String normalize(
    String raw, {
    PhoneCountry country = PhoneCountry.congoDrc,
  }) => toE164(nationalPartOf(raw, country: country), country: country);

  /// Forme canonique d'un numéro, indicatif ÉTRANGER préservé.
  ///
  /// Contrairement à [normalize], qui ramène tout au pays de saisie, celle-ci
  /// ne suppose le pays par défaut que pour un numéro visiblement national
  /// (`0…` ou chiffres nus). Un `+242…` reste `+242…` : c'est ce qui permet
  /// de ne PAS confondre deux abonnés voisins qui partagent leurs neuf
  /// derniers chiffres.
  static String canonicalE164(
    String raw, {
    PhoneCountry country = PhoneCountry.congoDrc,
  }) {
    final hasExplicitPlus = raw.trimLeft().startsWith('+');
    final digits = digitsOnly(raw);
    if (digits.isEmpty) return '';

    if (hasExplicitPlus) return '+$digits';
    if (digits.startsWith('00')) return '+${digits.substring(2)}';
    if (digits.startsWith('0')) {
      return '${country.dialCode}${digits.substring(1)}';
    }
    if (digits.length <= country.nationalLength) {
      return '${country.dialCode}$digits';
    }
    // Plus long qu'un numéro national et sans `+` : déjà international.
    return '+$digits';
  }

  /// true si deux écritures désignent le même abonné. Sert de juge final
  /// derrière un pré-filtre SQL forcément grossier.
  static bool sameNumber(
    String a,
    String b, {
    PhoneCountry country = PhoneCountry.congoDrc,
  }) {
    final left = canonicalE164(a, country: country);
    if (left.isEmpty) return false;
    return left == canonicalE164(b, country: country);
  }

  /// true si la valeur porte un indicatif international AUTRE que celui du
  /// pays de saisie — le champ ne peut alors ni la découper ni la
  /// recomposer sans la détruire.
  static bool isForeign(
    String raw, {
    PhoneCountry country = PhoneCountry.congoDrc,
  }) {
    final canonical = canonicalE164(raw, country: country);
    if (canonical.isEmpty) return false;
    return !canonical.startsWith(country.dialCode);
  }

  /// true si la partie nationale porte exactement le nombre de chiffres
  /// attendu par le pays.
  static bool isValidNationalPart(
    String nationalPart, {
    PhoneCountry country = PhoneCountry.congoDrc,
  }) => digitsOnly(nationalPart).length == country.nationalLength;

  /// true si une valeur brute (E.164 ou format libre) constitue un numéro
  /// complet pour le pays.
  static bool isValid(
    String raw, {
    PhoneCountry country = PhoneCountry.congoDrc,
  }) => isValidNationalPart(
    nationalPartOf(raw, country: country),
    country: country,
  );
}
