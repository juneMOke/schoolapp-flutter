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
    email: email,
  );
}
