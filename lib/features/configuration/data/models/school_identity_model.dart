import 'package:json_annotation/json_annotation.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/school_identity.dart';

part 'school_identity_model.g.dart';

/// Miroir de `SchoolDto`. Les huit champs sont `@NotBlank` côté serveur, et
/// l'écriture est un **PUT complet** : le corps porte les huit, y compris ceux
/// que l'écran affiche en lecture seule. Les omettre rend 400.
@JsonSerializable()
class SchoolIdentityModel {
  final String? id;
  final String name;
  final String country;
  final String city;
  final String district;
  final String municipality;
  final String address;
  final String phone;

  /// Facultatif, contrairement aux huit autres (contrat back du 2026-09-24).
  ///
  /// ⚠️ **`null` quand le champ est vide, jamais `''`.** Le serveur traite
  /// l'absence et le `null` de la même façon — il CONSERVE la valeur déjà
  /// saisie — et c'est exactement ce qu'on veut d'un champ laissé vide. Envoyer
  /// une chaîne vide demanderait au serveur d'en faire quelque chose que le
  /// contrat ne dit pas.
  final String? tillPhone;

  /// Facultatif lui aussi, et même règle que [tillPhone] : absent ou `null`,
  /// le serveur conserve la valeur déjà enregistrée.
  final int? ticketCopies;

  final String email;

  const SchoolIdentityModel({
    required this.id,
    required this.name,
    required this.country,
    required this.city,
    required this.district,
    required this.municipality,
    required this.address,
    required this.phone,
    this.tillPhone,
    this.ticketCopies,
    required this.email,
  });

  factory SchoolIdentityModel.fromJson(Map<String, dynamic> json) =>
      _$SchoolIdentityModelFromJson(json);

  /// Le corps du PUT ne porte pas d'identifiant : il est dans le chemin, et le
  /// serveur le confronte à celui du jeton.
  factory SchoolIdentityModel.fromEntity(SchoolIdentity identity) =>
      SchoolIdentityModel(
        id: null,
        name: identity.name.trim(),
        country: identity.country.trim(),
        city: identity.city.trim(),
        district: identity.district.trim(),
        municipality: identity.municipality.trim(),
        address: identity.address.trim(),
        phone: identity.phone.trim(),
        tillPhone: identity.tillPhone.trim().isEmpty
            ? null
            : identity.tillPhone.trim(),
        ticketCopies: identity.ticketCopies,
        email: identity.email.trim(),
      );

  Map<String, dynamic> toJson() => _$SchoolIdentityModelToJson(this);

  /// [fallbackId] sert quand le serveur ne renvoie pas l'identifiant : celui de
  /// la session est le seul que le client manipule, et le seul qui vaille.
  SchoolIdentity toEntity({required String fallbackId}) => SchoolIdentity(
    id: id ?? fallbackId,
    name: name,
    country: country,
    city: city,
    district: district,
    municipality: municipality,
    address: address,
    phone: phone,
    tillPhone: tillPhone ?? '',
    ticketCopies: ticketCopies,
    email: email,
  );
}
