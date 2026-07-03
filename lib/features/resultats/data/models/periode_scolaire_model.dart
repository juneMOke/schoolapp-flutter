import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/core/helpers/date_only_json_helper.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/decoupage.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/periode_scolaire.dart';

/// Modèle d'une grande période de classe (`PeriodeScolaireResumeDto`), **parsé à
/// la main** (pas de `@JsonSerializable`) et tolérant : la clé wire `id` accepte
/// plusieurs noms (`periodeScolaireId` du contrat inclus) ; un `id` absent/vide
/// reste invalide. `startDate`/`endDate` sont des **dates pures** (`DateTime?`
/// via [DateOnlyJsonHelper], jamais un instant ISO) ; `courant` défaut `false`.
class PeriodeScolaireModel extends Equatable {
  final String id;
  final int ordre;
  final String? periodType;
  final String? statut;
  final String? libelle;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool courant;

  const PeriodeScolaireModel({
    required this.id,
    required this.ordre,
    this.periodType,
    this.statut,
    this.libelle,
    this.startDate,
    this.endDate,
    this.courant = false,
  });

  factory PeriodeScolaireModel.fromJson(Map<String, dynamic> json) {
    final id = _firstString(json, const [
      'periodeScolaireId',
      'id',
      'periodId',
    ]);
    if (id == null || id.trim().isEmpty) {
      throw const FormatException(
        'Invalid periode scolaire payload: id is missing',
      );
    }
    return PeriodeScolaireModel(
      id: id.trim(),
      ordre: _firstInt(json, const ['ordre', 'order', 'index', 'rang']) ?? 0,
      periodType: _firstString(json, const [
        'periodType',
        'decoupage',
        'type',
        'periodeType',
      ]),
      statut: _firstString(json, const ['statut', 'status', 'etat']),
      libelle: _firstString(json, const [
        'libelle',
        'label',
        'name',
        'nom',
        'title',
      ]),
      startDate: _parseDate(json['startDate']),
      endDate: _parseDate(json['endDate']),
      courant: json['courant'] == true,
    );
  }

  PeriodeScolaire toEntity() => PeriodeScolaire(
    id: id,
    ordre: ordre,
    decoupage: DecoupageX.fromApiValue(periodType),
    statut: StatutPeriodeX.fromApiValue(statut),
    libelle: (libelle?.trim().isEmpty ?? true) ? null : libelle!.trim(),
    startDate: startDate,
    endDate: endDate,
    courant: courant,
  );

  /// Date pure (`"2025-09-01"`) sous garde null : le helper attend un `String`.
  static DateTime? _parseDate(dynamic value) =>
      (value is String && value.trim().isNotEmpty)
      ? DateOnlyJsonHelper.fromJson(value.trim())
      : null;

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static int? _firstInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value.trim());
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [
    id,
    ordre,
    periodType,
    statut,
    libelle,
    startDate,
    endDate,
    courant,
  ];
}
