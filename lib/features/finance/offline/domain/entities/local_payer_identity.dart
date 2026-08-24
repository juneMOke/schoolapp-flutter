import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/search_normalization_helper.dart';

/// D'où l'écran tient ce payeur. Le guichetier doit pouvoir le distinguer :
/// « a déjà payé » est un fait constaté, « tuteur de l'élève » n'est qu'une
/// hypothèse — le tuteur n'est pas nécessairement celui qui vient à la caisse.
enum PayerOrigin {
  /// Retrouvé dans l'historique local des versements.
  previousPayment,

  /// Tuteur déclaré de l'élève, qui n'a peut-être jamais payé.
  guardian,
}

/// Un payeur proposable à l'encaissement, tel que la tablette le connaît
/// **localement**.
///
/// Ce n'est pas une personne référencée : le payeur n'a pas d'identifiant dans
/// le domaine, il n'existe que comme identité recopiée sur chaque versement.
/// Deux versements du même parent sont deux écritures indépendantes — c'est
/// pour cela que le rapprochement se fait sur une clé dérivée du nom
/// ([matchKey]) et jamais sur un id.
class LocalPayerIdentity extends Equatable {
  final String lastName;
  final String firstName;
  final String? middleName;

  /// Numéro E.164 connu pour ce payeur, ou `null`.
  ///
  /// Nul reste possible même depuis la v28 : un payeur dont les seuls
  /// versements sont antérieurs au palier remonte sans numéro. L'écran le
  /// propose alors quand même — l'identité suffit à éviter la ressaisie — et le
  /// guichetier complète le numéro, qui sera porté par le versement du jour.
  final String? phoneNumber;

  final PayerOrigin origin;

  /// Date du dernier versement de ce payeur (ISO-8601), `null` pour un tuteur
  /// qui n'a jamais payé.
  final String? lastPaidAt;

  /// Nombre de versements déjà encaissés de ce payeur, `0` pour un tuteur.
  final int paymentCount;

  const LocalPayerIdentity({
    required this.lastName,
    required this.firstName,
    this.middleName,
    this.phoneNumber,
    required this.origin,
    this.lastPaidAt,
    this.paymentCount = 0,
  });

  /// Nom affichable, dans l'ordre de la modale d'encaissement
  /// (Nom · Post-nom · Prénom) — les parties vides sont omises.
  String get fullName => [
    lastName.trim(),
    middleName?.trim() ?? '',
    firstName.trim(),
  ].where((part) => part.isNotEmpty).join(' ');

  /// Clé de rapprochement de DEUX identités de payeur : minuscules, accents
  /// pliés, espaces resserrés.
  ///
  /// Elle est calculée **en Dart et jamais en SQL** : `LOWER()` de SQLite ne
  /// plie que l'ASCII, si bien que `José` et `jose` y resteraient deux
  /// personnes. Le même parent apparaîtrait deux fois dans la liste, chacune
  /// avec la moitié de son historique — exactement la ressaisie que l'écran
  /// cherche à supprimer.
  ///
  /// Le numéro n'entre PAS dans la clé : un payeur qui change de numéro reste
  /// le même payeur, et l'inclure rouvrirait un doublon à chaque changement.
  String get matchKey =>
      [lastName, middleName ?? '', firstName].map(_normalizedPart).join('|');

  static String _normalizedPart(String value) =>
      SearchNormalizationHelper.normalize(
        value.trim(),
      ).replaceAll(RegExp(r'\s+'), ' ');

  LocalPayerIdentity copyWith({
    String? phoneNumber,
    PayerOrigin? origin,
    String? lastPaidAt,
    int? paymentCount,
  }) => LocalPayerIdentity(
    lastName: lastName,
    firstName: firstName,
    middleName: middleName,
    phoneNumber: phoneNumber ?? this.phoneNumber,
    origin: origin ?? this.origin,
    lastPaidAt: lastPaidAt ?? this.lastPaidAt,
    paymentCount: paymentCount ?? this.paymentCount,
  );

  @override
  List<Object?> get props => [
    lastName,
    firstName,
    middleName,
    phoneNumber,
    origin,
    lastPaidAt,
    paymentCount,
  ];
}
