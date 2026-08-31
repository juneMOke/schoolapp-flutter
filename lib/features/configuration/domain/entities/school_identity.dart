import 'package:equatable/equatable.dart';

/// Identité de l'établissement telle que `GET/PUT /schools/{id}` la porte.
///
/// **Les huit champs sont obligatoires côté serveur** (`@NotBlank`, plus
/// `@Email` sur le dernier). Pays et ville sont figés à l'écran — l'application
/// est déployée à Kinshasa — mais restent envoyés : les omettre rend 400.
///
/// Distincte de l'entité `School` de la feature `school`, qui est la lecture
/// **locale** de `ref_school` avec des champs facultatifs. Ici, tout est requis
/// et tout circule sur le réseau : deux sources, deux types.
class SchoolIdentity extends Equatable {
  final String id;
  final String name;
  final String country;
  final String city;

  /// District de Kinshasa (« Lukunga »). Chaîne libre côté serveur : aucun
  /// référentiel géographique n'est servi, la cascade vit dans l'application.
  final String district;

  /// Commune (« Gombe ») — `municipality` sur le fil.
  final String municipality;

  final String address;
  final String phone;
  final String email;

  const SchoolIdentity({
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

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Champs requis encore vides, dans l'ordre du formulaire.
  ///
  /// Rendus **nommés** plutôt que comptés : « À compléter : Commune, E-mail »
  /// dit où aller, « 2 champs manquants » laisse chercher.
  List<SchoolIdentityField> get missingFields => [
    if (name.trim().isEmpty) SchoolIdentityField.name,
    if (country.trim().isEmpty) SchoolIdentityField.country,
    if (city.trim().isEmpty) SchoolIdentityField.city,
    if (district.trim().isEmpty) SchoolIdentityField.district,
    if (municipality.trim().isEmpty) SchoolIdentityField.municipality,
    if (address.trim().isEmpty) SchoolIdentityField.address,
    if (phone.trim().isEmpty) SchoolIdentityField.phone,
    if (email.trim().isEmpty || !_email.hasMatch(email.trim()))
      SchoolIdentityField.email,
  ];

  bool get isComplete => missingFields.isEmpty;

  SchoolIdentity copyWith({
    String? name,
    String? country,
    String? city,
    String? district,
    String? municipality,
    String? address,
    String? phone,
    String? email,
  }) {
    return SchoolIdentity(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      city: city ?? this.city,
      district: district ?? this.district,
      // Changer de district vide la commune : la cascade descend, elle ne
      // conserve pas une commune qui n'appartient plus au district choisi.
      municipality: municipality ?? this.municipality,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    country,
    city,
    district,
    municipality,
    address,
    phone,
    email,
  ];
}

/// Les huit champs, nommables un par un pour le message de blocage.
enum SchoolIdentityField {
  name,
  country,
  city,
  district,
  municipality,
  address,
  phone,
  email,
}
