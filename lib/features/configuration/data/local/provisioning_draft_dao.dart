import 'dart:convert';

import 'package:school_app_flutter/features/configuration/data/models/provisioning_instant.dart';
import 'package:school_app_flutter/features/configuration/domain/entities/provisioning_request.dart';
import 'package:sqflite_common/sqlite_api.dart';

/// Ce qu'un brouillon rend quand on le relit : la saisie, et où elle en était.
class ProvisioningDraft {
  final ProvisioningRequest request;

  /// Étape affichée au moment du dernier enregistrement.
  final int step;

  /// Rang le plus avancé jamais atteint — c'est lui qui décide de ce qui reste
  /// cliquable au retour.
  final int maxStep;

  final DateTime updatedAt;

  const ProvisioningDraft({
    required this.request,
    required this.step,
    required this.maxStep,
    required this.updatedAt,
  });
}

/// Persistance du brouillon de mise en service.
///
/// **Toujours scopé `(schoolId, userId)`.** Une tablette peut servir deux
/// écoles, et le brouillon aboutit à une écriture irréversible : le relire hors
/// de son école ferait activer la mauvaise.
class ProvisioningDraftDao {
  final Database _db;

  const ProvisioningDraftDao(this._db);

  static const String _table = 'provisioning_drafts';

  /// Écrit ou remplace le brouillon.
  Future<void> save({
    required String schoolId,
    required String userId,
    required ProvisioningRequest request,
    required int step,
    required int maxStep,
  }) async {
    await _db.insert(_table, {
      'school_id': schoolId,
      'user_id': userId,
      'payload': jsonEncode(_encode(request)),
      'step': step,
      'max_step': maxStep,
      'updated_at': DateTime.now().toUtc().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Relit le brouillon, ou `null` s'il n'y en a pas.
  ///
  /// Un brouillon **illisible** vaut absent : le format a pu changer entre deux
  /// versions de l'application, et refuser d'ouvrir l'assistant pour cette
  /// raison enfermerait l'agent hors du seul écran qui peut le débloquer.
  Future<ProvisioningDraft?> find({
    required String schoolId,
    required String userId,
  }) async {
    final rows = await _db.query(
      _table,
      where: 'school_id = ? AND user_id = ?',
      whereArgs: [schoolId, userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    try {
      final payload = jsonDecode(row['payload'] as String);
      if (payload is! Map<String, dynamic>) return null;
      return ProvisioningDraft(
        request: _decode(payload),
        step: (row['step'] as int?) ?? 0,
        maxStep: (row['max_step'] as int?) ?? 0,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (row['updated_at'] as int?) ?? 0,
          isUtc: true,
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Détruit le brouillon.
  ///
  /// À n'appeler qu'**au succès de l'activation**. Un brouillon qui survit à
  /// une activation réussie rejouerait l'assistant jusqu'au refus « année déjà
  /// existante », que rien à l'écran ne saurait expliquer.
  Future<void> delete({
    required String schoolId,
    required String userId,
  }) async {
    await _db.delete(
      _table,
      where: 'school_id = ? AND user_id = ?',
      whereArgs: [schoolId, userId],
    );
  }

  // ── Encodage ────────────────────────────────────────────────────────────────
  // À la main plutôt que par le modèle réseau : celui-ci n'a pas de `fromJson`
  // (il ne fait que partir), et surtout il applique déjà les règles du serveur —
  // omission d'un cycle vide, exclusion du compteur sur un niveau à sections.
  // Un brouillon doit se relire TEL QUEL, y compris à moitié rempli.

  static Map<String, dynamic> _encode(ProvisioningRequest request) {
    final year = request.academicYear;
    return {
      if (year != null)
        'academicYear': {
          'name': year.name,
          'startDate': ProvisioningInstant.toUtcInstant(year.startDate),
          'endDate': ProvisioningInstant.toUtcInstant(year.endDate),
          'current': year.current,
        },
      'defaultClassroomsPerLevel': request.defaultClassroomsPerLevel,
      'cycles': request.cycles
          .map(
            (cycle) => {
              'catalogCode': cycle.catalogCode,
              'levels': cycle.levels
                  .map(
                    (level) => {
                      'catalogCode': level.catalogCode,
                      'classrooms': level.classrooms,
                      'sections': level.sections
                          .map(
                            (section) => {
                              'officialCode': section.officialCode,
                              'classrooms': section.classrooms,
                            },
                          )
                          .toList(),
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
      'fees': request.fees
          .map(
            (fee) => {
              'feeCode': fee.feeCode,
              'label': fee.label,
              'amountInCents': fee.amountInCents,
              'currency': fee.currency,
              'dueAt': fee.dueAt == null
                  ? null
                  : ProvisioningInstant.toUtcInstant(fee.dueAt!),
              'appliesTo': {
                'scope': fee.appliesTo.scope.wire,
                'levelCatalogCodes': fee.appliesTo.levelCatalogCodes,
              },
            },
          )
          .toList(),
    };
  }

  static ProvisioningRequest _decode(Map<String, dynamic> json) {
    final year = json['academicYear'];
    return ProvisioningRequest(
      academicYear: year is Map<String, dynamic>
          ? AcademicYearInput(
              name: (year['name'] as String?) ?? '',
              startDate:
                  ProvisioningInstant.parse(year['startDate']) ??
                  DateTime.now(),
              endDate:
                  ProvisioningInstant.parse(year['endDate']) ?? DateTime.now(),
              current: (year['current'] as bool?) ?? true,
            )
          : null,
      defaultClassroomsPerLevel: json['defaultClassroomsPerLevel'] as int?,
      cycles: _list(json['cycles'])
          .map(
            (cycle) => CycleInput(
              catalogCode: (cycle['catalogCode'] as String?) ?? '',
              levels: _list(cycle['levels'])
                  .map(
                    (level) => LevelInput(
                      catalogCode: (level['catalogCode'] as String?) ?? '',
                      classrooms: level['classrooms'] as int?,
                      sections: _list(level['sections'])
                          .map(
                            (section) => SectionInput(
                              officialCode:
                                  (section['officialCode'] as String?) ?? '',
                              classrooms: (section['classrooms'] as int?) ?? 0,
                            ),
                          )
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      fees: _list(json['fees']).map((fee) {
        final scope = fee['appliesTo'];
        return FeeInput(
          feeCode: (fee['feeCode'] as String?) ?? '',
          label: (fee['label'] as String?) ?? '',
          amountInCents: (fee['amountInCents'] as int?) ?? 0,
          currency: (fee['currency'] as String?) ?? 'USD',
          dueAt: ProvisioningInstant.parse(fee['dueAt']),
          appliesTo: scope is Map<String, dynamic>
              ? FeeScopeInput(
                  scope: FeeScope.fromWire(scope['scope'] as String?),
                  levelCatalogCodes: _list(
                    scope['levelCatalogCodes'],
                  ).cast<Object?>().whereType<String>().toList(),
                )
              : const FeeScopeInput.allOpenedLevels(),
        );
      }).toList(),
    );
  }

  static List<dynamic> _list(Object? raw) => raw is List ? raw : const [];
}
