import 'package:equatable/equatable.dart';

/// État du numéro de téléphone saisi.
enum PayerPhoneStatus {
  /// Rien de saisi.
  missing,

  /// Entamé, mais en dessous du seuil de validité. **On ne juge pas un numéro à
  /// moitié tapé** : aucune recherche au répertoire, et à l'écran « incomplet »
  /// plutôt qu'« absent ».
  incomplete,

  /// Assez de chiffres pour être un numéro, donc pour chercher au répertoire.
  usable,
}

/// Celui qui paie — le pivot de la vente.
///
/// **Ce n'est pas nécessairement un parent d'élève** : un ancien élève qui
/// retire son dossier paye pour lui-même. C'est pourquoi le répertoire des
/// payeurs est autonome et ne se déduit pas de l'effectif.
///
/// Trois champs d'identité, comme la Facturation et comme le serveur les accepte
/// — le nom composé qui s'imprime est **dérivé serveur**.
class CartPayer extends Equatable {
  final String lastName;
  final String middleName;
  final String firstName;

  /// Tel que saisi. La normalisation E.164 se fait au moment de pousser, pas à
  /// chaque frappe.
  final String phoneNumber;

  /// Vrai si ce payeur a été reconnu au répertoire.
  ///
  /// **Retombe à faux dès que le numéro change** : un badge « Payeur connu » qui
  /// survivrait à la modification de la clé qui l'a établi affirmerait un fait
  /// qui n'est plus vérifié.
  final bool knownFromDirectory;

  const CartPayer({
    this.lastName = '',
    this.middleName = '',
    this.firstName = '',
    this.phoneNumber = '',
    this.knownFromDirectory = false,
  });

  /// Nombre minimal de chiffres significatifs pour qu'un numéro soit exploitable
  /// — c'est aussi la longueur de la clé de rapprochement du répertoire.
  static const int minSignificantDigits = 9;

  /// Les chiffres seuls, indicatif compris.
  String get digits => phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

  /// Les 9 derniers chiffres — **la clé métier du payeur**.
  ///
  /// `0810220145`, `+243 810 220 145` et `243810220145` désignent la même
  /// personne. Calculée en Dart et jamais en SQL : `LOWER()` de SQLite ne plie
  /// pas les accents, et un pré-filtre sur le préfixe confondrait `+242` et
  /// `+243`.
  String? get matchKey {
    final all = digits;
    if (all.length < minSignificantDigits) return null;
    return all.substring(all.length - minSignificantDigits);
  }

  PayerPhoneStatus get phoneStatus {
    if (digits.isEmpty) return PayerPhoneStatus.missing;
    return digits.length < minSignificantDigits
        ? PayerPhoneStatus.incomplete
        : PayerPhoneStatus.usable;
  }

  CartPayer copyWith({
    String? lastName,
    String? middleName,
    String? firstName,
    String? phoneNumber,
    bool? knownFromDirectory,
  }) {
    final nextPhone = phoneNumber ?? this.phoneNumber;
    return CartPayer(
      lastName: lastName ?? this.lastName,
      middleName: middleName ?? this.middleName,
      firstName: firstName ?? this.firstName,
      phoneNumber: nextPhone,
      // Le badge tombe de lui-même quand la clé change : le tenir à jour depuis
      // l'écran laisserait un chemin par lequel il survivrait à son fait.
      knownFromDirectory: nextPhone == this.phoneNumber
          ? (knownFromDirectory ?? this.knownFromDirectory)
          : false,
    );
  }

  @override
  List<Object?> get props => [
    lastName,
    middleName,
    firstName,
    phoneNumber,
    knownFromDirectory,
  ];
}
