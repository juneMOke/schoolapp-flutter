import 'package:school_app_flutter/core/geo/geo_label_matcher.dart';

/// Ville → district → commune → quartiers.
typedef GeoTree = Map<String, Map<String, Map<String, List<String>>>>;

/// Ville → district → commune → (libellé affiché → nom du quartier).
///
/// Le libellé affiché porte le code postal quand le référentiel le connaît
/// (« Matonge (1234) ») ; le nom seul est ce qui s'enregistre.
typedef GeoDisplayTree =
    Map<String, Map<String, Map<String, Map<String, String>>>>;

/// Résultat du décodage du référentiel géographique.
class ParsedAddressGeoCatalog {
  final GeoTree data;
  final GeoDisplayTree neighborhoodDisplayMaps;

  const ParsedAddressGeoCatalog({
    required this.data,
    required this.neighborhoodDisplayMaps,
  });
}

/// Décode le JSON du référentiel géographique, dans ses deux formats.
///
/// - **structuré** (`{ville, districts: [{nom, communes: [{nom, quartiers}]}]}`),
///   où un quartier peut porter son `code_postal` ;
/// - **historique** (`{ville: {district: {commune: [quartiers]}}}`), sans code
///   postal.
class AddressGeoCatalogParser {
  AddressGeoCatalogParser._();

  static ParsedAddressGeoCatalog parse(
    Map<String, dynamic> json, {
    required String defaultCity,
  }) {
    if (json['districts'] is List) {
      return _parseStructured(json, defaultCity);
    }
    return _parseLegacy(json);
  }

  static ParsedAddressGeoCatalog _parseStructured(
    Map<String, dynamic> json,
    String defaultCity,
  ) {
    final data = <String, Map<String, Map<String, List<String>>>>{};
    final displayMaps =
        <String, Map<String, Map<String, Map<String, String>>>>{};

    final city = GeoLabelMatcher.nonEmpty(json['ville']) ?? defaultCity;
    final districtsList = json['districts'];
    if (districtsList is! List) {
      return const ParsedAddressGeoCatalog(
        data: {},
        neighborhoodDisplayMaps: {},
      );
    }

    final districts = <String, Map<String, List<String>>>{};

    for (final districtItem in districtsList.whereType<Map>()) {
      final districtMap = Map<String, dynamic>.from(districtItem);
      final districtName = GeoLabelMatcher.nonEmpty(districtMap['nom']);
      final communesList = districtMap['communes'];
      if (districtName == null || communesList is! List) continue;

      final municipalities = <String, List<String>>{};
      final municipalityDisplayMaps = <String, Map<String, String>>{};

      for (final communeItem in communesList.whereType<Map>()) {
        final communeMap = Map<String, dynamic>.from(communeItem);
        final communeName = GeoLabelMatcher.nonEmpty(communeMap['nom']);
        final neighborhoodsList = communeMap['quartiers'];
        if (communeName == null || neighborhoodsList is! List) continue;

        final (neighborhoods, displayToName) = _parseNeighborhoods(
          neighborhoodsList,
        );
        if (neighborhoods.isEmpty) continue;

        municipalities[communeName] = List<String>.unmodifiable(neighborhoods);
        municipalityDisplayMaps[communeName] = Map<String, String>.unmodifiable(
          displayToName,
        );
      }

      if (municipalities.isNotEmpty) {
        districts[districtName] = municipalities;
        displayMaps[city] ??= <String, Map<String, Map<String, String>>>{};
        displayMaps[city]![districtName] = municipalityDisplayMaps;
      }
    }

    if (districts.isNotEmpty) {
      data[city] = districts;
    }

    return ParsedAddressGeoCatalog(
      data: data,
      neighborhoodDisplayMaps: displayMaps,
    );
  }

  /// Quartiers d'une commune, dédoublonnés, et leur libellé affiché.
  static (List<String>, Map<String, String>) _parseNeighborhoods(
    List<dynamic> items,
  ) {
    final neighborhoods = <String>[];
    final displayToName = <String, String>{};

    for (final item in items) {
      final neighborhood = switch (item) {
        String value => GeoLabelMatcher.nonEmpty(value),
        Map map => GeoLabelMatcher.nonEmpty(map['nom']),
        _ => null,
      };
      final postalCode = switch (item) {
        Map map => GeoLabelMatcher.nonEmpty(map['code_postal']),
        _ => null,
      };

      if (neighborhood == null || neighborhoods.contains(neighborhood)) {
        continue;
      }

      final display = postalCode == null
          ? neighborhood
          : '$neighborhood ($postalCode)';

      neighborhoods.add(neighborhood);
      displayToName[display] = neighborhood;
    }

    return (neighborhoods, displayToName);
  }

  static ParsedAddressGeoCatalog _parseLegacy(Map<String, dynamic> json) {
    final result = <String, Map<String, Map<String, List<String>>>>{};
    final displayMaps =
        <String, Map<String, Map<String, Map<String, String>>>>{};

    for (final cityEntry in json.entries) {
      final districtsJson = cityEntry.value;
      if (districtsJson is! Map<String, dynamic>) continue;

      final districts = <String, Map<String, List<String>>>{};
      for (final districtEntry in districtsJson.entries) {
        final municipalitiesJson = districtEntry.value;
        if (municipalitiesJson is! Map<String, dynamic>) continue;

        final municipalities = <String, List<String>>{};
        final municipalityDisplayMaps = <String, Map<String, String>>{};

        for (final municipalityEntry in municipalitiesJson.entries) {
          final neighborhoodsJson = municipalityEntry.value;
          if (neighborhoodsJson is! List) continue;

          final neighborhoods = neighborhoodsJson
              .whereType<String>()
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toList(growable: false);

          municipalities[municipalityEntry.key] = neighborhoods;
          municipalityDisplayMaps[municipalityEntry.key] =
              Map<String, String>.unmodifiable({
                for (final neighborhood in neighborhoods)
                  neighborhood: neighborhood,
              });
        }

        districts[districtEntry.key] = municipalities;
        displayMaps[cityEntry.key] ??=
            <String, Map<String, Map<String, String>>>{};
        displayMaps[cityEntry.key]![districtEntry.key] =
            municipalityDisplayMaps;
      }

      result[cityEntry.key] = districts;
    }

    return ParsedAddressGeoCatalog(
      data: result,
      neighborhoodDisplayMaps: displayMaps,
    );
  }
}
