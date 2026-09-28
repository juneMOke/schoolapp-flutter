import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/geo/address_geo_catalog_parser.dart';
import 'package:school_app_flutter/core/geo/geo_label_matcher.dart';

/// Référentiel géographique des adresses : ville → district → commune →
/// quartier, chargé une fois depuis les assets puis gardé en mémoire.
///
/// Partagé par tout formulaire d'adresse (inscription d'un élève, identité de
/// l'école, fiche d'un agent) : une cascade qui divergerait d'un écran à l'autre
/// produirait des adresses que les autres ne sauraient plus relire.
class AddressGeoCatalog {
  static const String defaultCity = 'Kinshasa';
  static const String _assetPath = 'assets/catalogs/address_geo_catalog.json';

  static AddressGeoCatalog? _cache;

  final GeoTree _data;
  final GeoDisplayTree _neighborhoodDisplayMaps;

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

    final parsed = AddressGeoCatalogParser.parse(
      decoded,
      defaultCity: defaultCity,
    );
    final catalog = AddressGeoCatalog._(
      parsed.data,
      parsed.neighborhoodDisplayMaps,
    );
    _cache = catalog;
    return catalog;
  }

  List<String> cityOptions({String? include}) {
    return GeoLabelMatcher.withOptional(
      _data.keys.toList(growable: false),
      include,
    );
  }

  String? firstCity() {
    if (_data.isEmpty) {
      return null;
    }
    return _data.keys.first;
  }

  String? resolveCity(String? city) {
    return GeoLabelMatcher.resolve(_data.keys, city);
  }

  List<String> districtsForCity(String city, {String? include}) {
    final districts =
        _data[city]?.keys.toList(growable: false) ?? const <String>[];
    return GeoLabelMatcher.withOptional(districts, include);
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
    return GeoLabelMatcher.resolve(districts, district);
  }

  List<String> municipalitiesForDistrict(
    String city,
    String district, {
    String? include,
  }) {
    final municipalities =
        _data[city]?[district]?.keys.toList(growable: false) ??
        const <String>[];
    return GeoLabelMatcher.withOptional(municipalities, include);
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
    return GeoLabelMatcher.resolve(municipalities, municipality);
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

    return GeoLabelMatcher.withOptional(options, include);
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

    final direct = GeoLabelMatcher.resolve(map.keys, value);
    if (direct != null) {
      return map[direct];
    }

    final names = map.values.toSet();
    final byName = GeoLabelMatcher.resolve(names, value);
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
}
