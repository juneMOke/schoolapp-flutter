import 'dart:convert';

import 'package:flutter/services.dart';

class AddressGeoCatalog {
  static const String defaultCity = 'Kinshasa';
  static const String _assetPath = 'assets/catalogs/address_geo_catalog.json';

  static AddressGeoCatalog? _cache;

  final Map<String, Map<String, Map<String, List<String>>>> _data;
  final Map<String, Map<String, Map<String, Map<String, String>>>>
  _neighborhoodDisplayMaps;

  const AddressGeoCatalog._(this._data, this._neighborhoodDisplayMaps);

  static Future<AddressGeoCatalog> load() async {
    final cached = _cache;
    if (cached != null) {
      return cached;
    }

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid address geo catalog format');
    }

    final parsed = _parseCatalog(decoded);
    final catalog = AddressGeoCatalog._(
      parsed.data,
      parsed.neighborhoodDisplayMaps,
    );
    _cache = catalog;
    return catalog;
  }

  List<String> cityOptions({String? include}) {
    return _withOptional(_data.keys.toList(growable: false), include);
  }

  String? firstCity() {
    if (_data.isEmpty) {
      return null;
    }
    return _data.keys.first;
  }

  String? resolveCity(String? city) {
    return _resolveKey(_data.keys, city);
  }

  List<String> districtsForCity(String city, {String? include}) {
    final districts =
        _data[city]?.keys.toList(growable: false) ?? const <String>[];
    return _withOptional(districts, include);
  }

  String? firstDistrictForCity(String city) {
    final districts = _data[city];
    if (districts == null || districts.isEmpty) {
      return null;
    }
    return districts.keys.first;
  }

  String? resolveDistrict(String city, String? district) {
    final districts = _data[city]?.keys;
    if (districts == null) {
      return null;
    }
    return _resolveKey(districts, district);
  }

  List<String> municipalitiesForDistrict(
    String city,
    String district, {
    String? include,
  }) {
    final municipalities =
        _data[city]?[district]?.keys.toList(growable: false) ??
        const <String>[];
    return _withOptional(municipalities, include);
  }

  String? firstMunicipalityForDistrict(String city, String district) {
    final municipalities = _data[city]?[district];
    if (municipalities == null || municipalities.isEmpty) {
      return null;
    }
    return municipalities.keys.first;
  }

  String? resolveMunicipality(
    String city,
    String district,
    String? municipality,
  ) {
    final municipalities = _data[city]?[district]?.keys;
    if (municipalities == null) {
      return null;
    }
    return _resolveKey(municipalities, municipality);
  }

  List<String> neighborhoodsForMunicipality(
    String city,
    String district,
    String municipality, {
    String? include,
  }) {
    final displayMap = _neighborhoodDisplayMaps[city]?[district]?[municipality];
    final options =
        displayMap?.keys.toList(growable: false) ?? const <String>[];

    return _withOptional(options, include);
  }

  String? firstNeighborhoodDisplayForMunicipality(
    String city,
    String district,
    String municipality,
  ) {
    final options = _neighborhoodDisplayMaps[city]?[district]?[municipality];
    if (options == null || options.isEmpty) {
      return null;
    }
    return options.keys.first;
  }

  String neighborhoodNameFromDisplay(
    String city,
    String district,
    String municipality,
    String display,
  ) {
    final map = _neighborhoodDisplayMaps[city]?[district]?[municipality];
    if (map == null) {
      return display;
    }

    return map[display] ?? display;
  }

  String? resolveNeighborhoodName(
    String city,
    String district,
    String municipality,
    String? value,
  ) {
    final map = _neighborhoodDisplayMaps[city]?[district]?[municipality];
    if (map == null) {
      return null;
    }

    final direct = _resolveKey(map.keys, value);
    if (direct != null) {
      return map[direct];
    }

    final names = map.values.toSet();
    final byName = _resolveKey(names, value);
    return byName;
  }

  String neighborhoodDisplayFromName(
    String city,
    String district,
    String municipality,
    String name,
  ) {
    final map = _neighborhoodDisplayMaps[city]?[district]?[municipality];
    if (map == null) {
      return name;
    }

    for (final entry in map.entries) {
      if (entry.value == name) {
        return entry.key;
      }
    }

    return name;
  }

  static _ParsedCatalog _parseCatalog(Map<String, dynamic> json) {
    if (json['districts'] is List) {
      return _parseStructuredCatalog(json);
    }

    return _parseLegacyCatalog(json);
  }

  static _ParsedCatalog _parseStructuredCatalog(Map<String, dynamic> json) {
    final data = <String, Map<String, Map<String, List<String>>>>{};
    final displayMaps =
        <String, Map<String, Map<String, Map<String, String>>>>{};

    final city = _asNonEmptyString(json['ville']) ?? defaultCity;
    final districtsList = json['districts'];
    if (districtsList is! List) {
      return const _ParsedCatalog(data: {}, neighborhoodDisplayMaps: {});
    }

    final districts = <String, Map<String, List<String>>>{};

    for (final districtItem in districtsList.whereType<Map>()) {
      final districtMap = Map<String, dynamic>.from(districtItem);
      final districtName = _asNonEmptyString(districtMap['nom']);
      if (districtName == null) {
        continue;
      }

      final communesList = districtMap['communes'];
      if (communesList is! List) {
        continue;
      }

      final municipalities = <String, List<String>>{};
      final municipalityDisplayMaps = <String, Map<String, String>>{};

      for (final communeItem in communesList.whereType<Map>()) {
        final communeMap = Map<String, dynamic>.from(communeItem);
        final communeName = _asNonEmptyString(communeMap['nom']);
        if (communeName == null) {
          continue;
        }

        final neighborhoodsList = communeMap['quartiers'];
        if (neighborhoodsList is! List) {
          continue;
        }

        final neighborhoods = <String>[];
        final displayToName = <String, String>{};

        for (final neighborhoodItem in neighborhoodsList) {
          final neighborhood = switch (neighborhoodItem) {
            String value => _asNonEmptyString(value),
            Map map => _asNonEmptyString(map['nom']),
            _ => null,
          };
          final postalCode = switch (neighborhoodItem) {
            Map map => _asNonEmptyString(map['code_postal']),
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

        if (neighborhoods.isNotEmpty) {
          municipalities[communeName] = List<String>.unmodifiable(
            neighborhoods,
          );
          municipalityDisplayMaps[communeName] =
              Map<String, String>.unmodifiable(displayToName);
        }
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

    return _ParsedCatalog(data: data, neighborhoodDisplayMaps: displayMaps);
  }

  static _ParsedCatalog _parseLegacyCatalog(Map<String, dynamic> json) {
    final result = <String, Map<String, Map<String, List<String>>>>{};
    final displayMaps =
        <String, Map<String, Map<String, Map<String, String>>>>{};

    for (final cityEntry in json.entries) {
      final districtsJson = cityEntry.value;
      if (districtsJson is! Map<String, dynamic>) {
        continue;
      }

      final districts = <String, Map<String, List<String>>>{};
      for (final districtEntry in districtsJson.entries) {
        final municipalitiesJson = districtEntry.value;
        if (municipalitiesJson is! Map<String, dynamic>) {
          continue;
        }

        final municipalities = <String, List<String>>{};
        final municipalityDisplayMaps = <String, Map<String, String>>{};

        for (final municipalityEntry in municipalitiesJson.entries) {
          final neighborhoodsJson = municipalityEntry.value;
          if (neighborhoodsJson is! List) {
            continue;
          }

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

    return _ParsedCatalog(data: result, neighborhoodDisplayMaps: displayMaps);
  }

  static String? _asNonEmptyString(Object? value) {
    if (value is! String) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<String> _withOptional(List<String> base, String? include) {
    final value = include?.trim() ?? '';
    if (value.isEmpty || base.contains(value)) {
      return List<String>.unmodifiable(base);
    }

    return List<String>.unmodifiable(<String>[value, ...base]);
  }

  static String? _resolveKey(Iterable<String> options, String? raw) {
    final candidate = _asNonEmptyString(raw);
    if (candidate == null) {
      return null;
    }

    for (final option in options) {
      if (option == candidate) {
        return option;
      }
    }

    final normalizedCandidate = _normalize(candidate);
    for (final option in options) {
      if (_normalize(option) == normalizedCandidate) {
        return option;
      }
    }

    return null;
  }

  static String _normalize(String value) {
    final lowered = value.toLowerCase();
    final buffer = StringBuffer();
    for (final rune in lowered.runes) {
      final char = String.fromCharCode(rune);
      final normalized = switch (char) {
        'a' ||
        'b' ||
        'c' ||
        'd' ||
        'e' ||
        'f' ||
        'g' ||
        'h' ||
        'i' ||
        'j' ||
        'k' ||
        'l' ||
        'm' ||
        'n' ||
        'o' ||
        'p' ||
        'q' ||
        'r' ||
        's' ||
        't' ||
        'u' ||
        'v' ||
        'w' ||
        'x' ||
        'y' ||
        'z' ||
        '0' ||
        '1' ||
        '2' ||
        '3' ||
        '4' ||
        '5' ||
        '6' ||
        '7' ||
        '8' ||
        '9' => char,
        'à' || 'á' || 'â' || 'ä' || 'ã' || 'å' => 'a',
        'ç' => 'c',
        'è' || 'é' || 'ê' || 'ë' => 'e',
        'ì' || 'í' || 'î' || 'ï' => 'i',
        'ñ' => 'n',
        'ò' || 'ó' || 'ô' || 'ö' || 'õ' => 'o',
        'ù' || 'ú' || 'û' || 'ü' => 'u',
        'ý' || 'ÿ' => 'y',
        _ => '',
      };
      buffer.write(normalized);
    }
    return buffer.toString();
  }
}

class _ParsedCatalog {
  final Map<String, Map<String, Map<String, List<String>>>> data;
  final Map<String, Map<String, Map<String, Map<String, String>>>>
  neighborhoodDisplayMaps;

  const _ParsedCatalog({
    required this.data,
    required this.neighborhoodDisplayMaps,
  });
}
