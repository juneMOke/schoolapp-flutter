import 'dart:convert';

import 'package:flutter/services.dart';

/// A single year/level inside a cycle (e.g. "1ère Année Primaire").
class EducationYear {
  final int id;
  final String nom;
  final int ordre;

  const EducationYear({
    required this.id,
    required this.nom,
    required this.ordre,
  });
}

/// A cycle of the DRC education system (e.g. "Cycle Primaire").
class EducationCycle {
  final int id;
  final String nom;
  final String code;
  final String description;
  final List<EducationYear> annees;

  const EducationCycle({
    required this.id,
    required this.nom,
    required this.code,
    required this.description,
    required this.annees,
  });
}

/// Parses and exposes the education cycles catalog.
///
/// Used by [PreviousAcademicInfoStep] to power the Cycle and Niveau dropdowns.
class EducationCyclesCatalog {
  static const String _assetPath =
      'assets/catalogs/education_cycles_catalog.json';

  static EducationCyclesCatalog? _cache;

  final List<EducationCycle> cycles;

  const EducationCyclesCatalog._(this.cycles);

  // ---------------------------------------------------------------------------
  // Loading
  // ---------------------------------------------------------------------------

  static Future<EducationCyclesCatalog> load() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid education cycles catalog format');
    }

    final catalog = EducationCyclesCatalog._(_parseCycles(decoded));
    _cache = catalog;
    return catalog;
  }

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// All cycle names in declaration order.
  List<String> get cycleNames =>
      cycles.map((c) => c.nom).toList(growable: false);

  /// Returns the [EducationCycle] matching [name] (case-insensitive, accent-
  /// tolerant), or `null` if no match is found.
  EducationCycle? resolveCycle(String? name) {
    final candidate = _normalize(name?.trim() ?? '');
    if (candidate.isEmpty) return null;

    for (final cycle in cycles) {
      if (_normalize(cycle.nom) == candidate) return cycle;
    }
    return null;
  }

  /// Convenience: first cycle in the list (used as default).
  EducationCycle? get firstCycle => cycles.isEmpty ? null : cycles.first;

  /// Level names for [cycleName], or empty list if cycle not found.
  List<String> yearsForCycle(String cycleName) {
    final cycle = resolveCycle(cycleName);
    if (cycle == null) return const <String>[];
    return cycle.annees.map((a) => a.nom).toList(growable: false);
  }

  /// Returns the level name that best matches [levelName] inside [cycleName],
  /// or `null` when not found.
  String? resolveLevel(String cycleName, String? levelName) {
    final candidate = _normalize(levelName?.trim() ?? '');
    if (candidate.isEmpty) return null;

    final cycle = resolveCycle(cycleName);
    if (cycle == null) return null;

    for (final year in cycle.annees) {
      if (_normalize(year.nom) == candidate) return year.nom;
    }
    return null;
  }

  /// First level in [cycleName], used as fallback default.
  String? firstLevelForCycle(String? cycleName) {
    if (cycleName == null) return null;
    final cycle = resolveCycle(cycleName);
    if (cycle == null || cycle.annees.isEmpty) return null;
    return cycle.annees.first.nom;
  }

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  static List<EducationCycle> _parseCycles(Map<String, dynamic> json) {
    final systeme = json['systeme_educatif'];
    if (systeme is! Map<String, dynamic>) return const [];

    final rawCycles = systeme['cycles'];
    if (rawCycles is! List) return const [];

    final result = <EducationCycle>[];
    for (final item in rawCycles.whereType<Map>()) {
      final cycleMap = Map<String, dynamic>.from(item);
      final id = cycleMap['id'];
      final nom = cycleMap['nom'];
      final code = cycleMap['code'];
      final description = cycleMap['description'];
      final rawAnnees = cycleMap['annees'];

      if (id is! int || nom is! String || code is! String) continue;

      final annees = <EducationYear>[];
      if (rawAnnees is List) {
        for (final anneeItem in rawAnnees.whereType<Map>()) {
          final anneeMap = Map<String, dynamic>.from(anneeItem);
          final aId = anneeMap['id'];
          final anom = anneeMap['nom'];
          final ordre = anneeMap['ordre'];
          if (aId is! int || anom is! String || ordre is! int) continue;
          annees.add(EducationYear(id: aId, nom: anom, ordre: ordre));
        }
      }

      result.add(
        EducationCycle(
          id: id,
          nom: nom,
          code: code,
          description: description is String ? description : '',
          annees: List<EducationYear>.unmodifiable(annees),
        ),
      );
    }
    return List<EducationCycle>.unmodifiable(result);
  }

  // ---------------------------------------------------------------------------
  // Normalisation helper (accent- and case-tolerant comparison)
  // ---------------------------------------------------------------------------

  static String _normalize(String value) {
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      final n = switch (char) {
        'à' || 'á' || 'â' || 'ä' || 'ã' || 'å' => 'a',
        'ç' => 'c',
        'è' || 'é' || 'ê' || 'ë' => 'e',
        'ì' || 'í' || 'î' || 'ï' => 'i',
        'ñ' => 'n',
        'ò' || 'ó' || 'ô' || 'ö' || 'õ' => 'o',
        'ù' || 'ú' || 'û' || 'ü' => 'u',
        'ý' || 'ÿ' => 'y',
        _ => RegExp(r'[a-z0-9 ]').hasMatch(char) ? char : '',
      };
      buffer.write(n);
    }
    return buffer.toString();
  }
}
