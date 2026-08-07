import 'package:equatable/equatable.dart';

/// Identité de l'établissement courant (le « tenant »), telle que le
/// référentiel offline la met à disposition (`ref_school`, cache mono-ligne).
///
/// Ce n'est pas une donnée d'année scolaire : elle ne change pas d'une année à
/// l'autre, d'où une entité propre plutôt qu'un champ du contexte académique.
class School extends Equatable {
  final String id;
  final String name;
  final String? country;
  final String? city;
  final String? district;
  final String? municipality;
  final String? address;
  final String? phone;
  final String? email;

  const School({
    required this.id,
    required this.name,
    this.country,
    this.city,
    this.district,
    this.municipality,
    this.address,
    this.phone,
    this.email,
  });

  /// Localité la plus parlante dont on dispose, ou `null` si le référentiel
  /// n'en porte aucune : la ville d'abord, puis la commune, puis le quartier.
  String? get locality {
    for (final candidate in [city, municipality, district]) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
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
