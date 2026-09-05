import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/enrollment/data/models/enrollment_stats_response_model.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_stats.dart';

/// La charge utile élargie, telle que la branche serveur la rend.
///
/// Reprise du contrat vérifié dans les DTO Java plutôt que du brief : noms de
/// champs, types, et les deux clés de bucket qui ne sont pas des dates.
const _payload = '''
{
  "context": {
    "schoolYear": "2026-2027",
    "period": "year",
    "periodStart": "2026-09-01",
    "periodEnd": "2026-09-06",
    "generatedAt": "2026-09-06T08:14:00Z"
  },
  "headcount": {
    "total": 363,
    "segments": [
      {"code": "FEMALE", "value": 182, "percent": 50},
      {"code": "MALE", "value": 181, "percent": 50}
    ]
  },
  "kpis": {
    "totalEnrollments": {"value": 363, "percentOfTotal": 100},
    "firstEnrollments": {"value": 184, "percentOfTotal": 51},
    "reEnrollments": {"value": 179, "percentOfTotal": 49},
    "preEnrollments": {"value": 0, "percentOfTotal": 0},
    "inProgress": {"value": 0, "percentOfTotal": 0}
  },
  "evolution": {
    "granularity": "month",
    "currentBucketIndex": 1,
    "axisStart": "2026-08-01",
    "axisEnd": "2026-09-30",
    "buckets": [
      {"key": "out-of-axis-before", "shortLabel": "avant", "longLabel": "Avant l'axe", "value": 2, "isCurrent": false},
      {"key": "2026-09", "shortLabel": "sept.", "longLabel": "septembre 2026", "value": 361, "isCurrent": true}
    ]
  },
  "distributionByCycle": {
    "cycles": [
      {
        "code": "PRIMARY",
        "label": "Primaire",
        "total": 200,
        "levels": [
          {
            "id": "3f1a0c4e-0000-4000-8000-000000000001",
            "code": "P1",
            "label": "1re année",
            "cycle": "PRIMARY",
            "value": 120
          }
        ]
      }
    ]
  },
  "distributionByGender": {
    "total": 363,
    "segments": [
      {"code": "FEMALE", "value": 182, "percent": 50},
      {"code": "MALE", "value": 181, "percent": 50}
    ]
  }
}
''';

EnrollmentStats _decode() => EnrollmentStatsResponseModel.fromJson(
  jsonDecode(_payload) as Map<String, dynamic>,
).toEntity();

void main() {
  group('effectif inscrit', () {
    test('le bloc `headcount` est lu, avec sa ventilation par sexe', () {
      final stats = _decode();

      expect(stats.headcount.total, 363);
      expect(stats.headcount.segments, hasLength(2));
      expect(stats.headcount.segments.first.value, 182);
    });

    test(
      'son total N\'EST PAS celui des cartes, et on ne les réconcilie pas',
      () {
        // `kpis.totalEnrollments` ajoute les pré-inscriptions et les dossiers en
        // cours ; ici les deux coïncident parce que ces compteurs valent zéro en
        // production, mais l'égalité n'est pas garantie et ne doit pas être
        // supposée. Ce test documente la distinction plutôt que de l'épingler.
        final stats = _decode();

        expect(stats.headcount.total, 363);
        expect(
          stats.kpis.totalEnrollments.value -
              stats.kpis.preEnrollments.value -
              stats.kpis.inProgress.value,
          363,
        );
      },
    );

    test('absent d\'une charge utile ancienne, il vaut zéro sans lever', () {
      final json = jsonDecode(_payload) as Map<String, dynamic>;
      json.remove('headcount');

      final stats = EnrollmentStatsResponseModel.fromJson(json).toEntity();

      expect(stats.headcount.total, 0);
      expect(stats.headcount.segments, isEmpty);
    });
  });

  group('les libellés du rythme viennent du serveur', () {
    test('court pour l\'axe, long pour l\'infobulle', () {
      final buckets = _decode().evolution.buckets;

      expect(buckets.last.shortLabel, 'sept.');
      expect(buckets.last.longLabel, 'septembre 2026');
    });

    test('une clé « hors axe » se lit sans être parsée comme une date', () {
      // Le piège : `out-of-axis-before` n'est pas une date. L'ancien code
      // dérivait le libellé d'axe de la clé et aurait affiché « fore ».
      final first = _decode().evolution.buckets.first;

      expect(first.key, 'out-of-axis-before');
      expect(first.shortLabel, 'avant');
      expect(first.value, 2);
    });

    test('un libellé manquant laisse un vide, JAMAIS la clé', () {
      // Se rabattre sur la clé ressusciterait exactement le défaut que ces
      // deux champs suppriment.
      final json = jsonDecode(_payload) as Map<String, dynamic>;
      final buckets =
          (json['evolution'] as Map<String, dynamic>)['buckets'] as List;
      (buckets.first as Map<String, dynamic>).remove('shortLabel');

      final stats = EnrollmentStatsResponseModel.fromJson(json).toEntity();

      expect(stats.evolution.buckets.first.shortLabel, '');
      expect(
        stats.evolution.buckets.first.shortLabel,
        isNot('out-of-axis-before'),
      );
    });

    test('l\'axe est lu, et il n\'est pas la fenêtre comptée', () {
      final stats = _decode();

      expect(stats.evolution.axisStart, DateTime.parse('2026-08-01'));
      expect(stats.evolution.axisEnd, DateTime.parse('2026-09-30'));
      // La fenêtre comptée, elle, vit sur le contexte.
      expect(stats.context.periodStart, DateTime.parse('2026-09-01'));
    });

    test(
      '`currentBucketIndex` est une position, décalée par la barre de tête',
      () {
        // Il se lit, il ne se recalcule pas : une barre « hors axe » en tête
        // décale tout d'un cran.
        final stats = _decode();

        expect(stats.evolution.currentBucketIndex, 1);
        expect(stats.evolution.buckets[1].isCurrent, isTrue);
      },
    );
  });

  group('niveaux et cycles savent enfin se nommer', () {
    test('un niveau porte son id, son libellé et son cycle', () {
      final level = _decode().distributionByCycle.cycles.first.levels.first;

      expect(level.id, '3f1a0c4e-0000-4000-8000-000000000001');
      expect(level.label, '1re année');
      expect(level.cycle, 'PRIMARY');
      expect(level.displayLabel, '1re année');
    });

    test('sans libellé, la ligne retombe sur son code', () {
      final json = jsonDecode(_payload) as Map<String, dynamic>;
      final cycles =
          (json['distributionByCycle'] as Map<String, dynamic>)['cycles']
              as List;
      final levels = (cycles.first as Map<String, dynamic>)['levels'] as List;
      (levels.first as Map<String, dynamic>).remove('label');

      final stats = EnrollmentStatsResponseModel.fromJson(json).toEntity();

      expect(
        stats.distributionByCycle.cycles.first.levels.first.displayLabel,
        'P1',
      );
    });

    test('un cycle porte son libellé', () {
      final cycle = _decode().distributionByCycle.cycles.first;

      expect(cycle.label, 'Primaire');
      expect(cycle.displayLabel, 'Primaire');
    });
  });
}
