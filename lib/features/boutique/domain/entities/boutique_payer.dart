import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/phone_number_format.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/cart_payer.dart';

/// Un payeur déjà venu à la caisse, tel que la tablette le connaît.
///
/// Ce n'est pas une personne référencée : c'est ce que les ventes locales
/// disent d'un numéro. Le rapprochement se fait sur les derniers chiffres
/// significatifs, jamais sur un identifiant qui n'existe pas.
class BoutiquePayer extends Equatable {
  final String lastName;
  final String middleName;
  final String firstName;
  final String phoneNumber;

  /// Nombre de ventes déjà encaissées à ce payeur — « Déjà au répertoire ·
  /// 3 ventes ».
  final int saleCount;

  /// Date de la vente la plus récente (ISO-8601), pour trier les propositions.
  final String? lastSoldAt;

  /// Vrai si l'identité est **découpée** en trois champs.
  ///
  /// Faux pour une vente descendue du delta, qui ne porte que son nom composé :
  /// le serveur dérive `payer_name` du triplet, et il ne redescend pas découpé
  /// sur les ventes d'avant l'alignement. Un payeur non découpé remplit quand
  /// même le formulaire — dans le seul champ « Nom » — ce qui vaut mieux que de
  /// faire tout retaper.
  final bool isSplit;

  const BoutiquePayer({
    required this.lastName,
    this.middleName = '',
    this.firstName = '',
    required this.phoneNumber,
    this.saleCount = 0,
    this.lastSoldAt,
    this.isSplit = true,
  });

  /// Nom affichable, dans l'ordre RDC — Nom · Post-nom · Prénom.
  ///
  /// Le même ordre que le serveur applique pour composer `payer_name` : le
  /// ticket imprimé au guichet et le reçu scellé doivent se ressembler.
  String get displayName => [
    lastName.trim(),
    middleName.trim(),
    firstName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  /// La clé métier : les derniers chiffres significatifs du numéro.
  String? get matchKey {
    final national = PhoneNumberFormat.nationalPartOf(phoneNumber);
    return national.isEmpty ? null : national;
  }

  BoutiquePayer withMoreSales(int extra) => BoutiquePayer(
    lastName: lastName,
    middleName: middleName,
    firstName: firstName,
    phoneNumber: phoneNumber,
    saleCount: saleCount + extra,
    lastSoldAt: lastSoldAt,
    isSplit: isSplit,
  );

  /// Remplit le bloc payeur du panier — « Utiliser ».
  ///
  /// Le téléphone est **normalisé au format du répertoire** : c'est lui la clé,
  /// et laisser deux écritures du même numéro ferait deux payeurs à la
  /// prochaine recherche.
  CartPayer toCartPayer() => CartPayer(
    lastName: lastName,
    middleName: middleName,
    firstName: firstName,
    phoneNumber: PhoneNumberFormat.canonicalE164(phoneNumber),
    knownFromDirectory: true,
  );

  @override
  List<Object?> get props => [
    lastName,
    middleName,
    firstName,
    phoneNumber,
    saleCount,
    lastSoldAt,
    isSplit,
  ];
}
