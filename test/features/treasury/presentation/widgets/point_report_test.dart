import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/treasury/domain/entities/treasury_dashboard.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/dashboard/evolution_panel.dart';

void main() {
  test('une heure ou un jour : le journalier de la journée', () {
    final day = DateTime(2026, 10, 22);
    expect(pointReport(EvolutionGranularity.hour, day).$1, 'RJ-20261022');
    expect(pointReport(EvolutionGranularity.day, day).$1, 'RJ-20261022');
  });

  test('une semaine coupée au 1er du mois : la semaine ISO entière', () {
    // Jeudi 1er octobre 2026 : la tranche S1 commence là, le rapport est
    // celui du lundi 28 septembre au samedi 3 octobre.
    final (id, from, to) = pointReport(
      EvolutionGranularity.week,
      DateTime(2026, 10, 1),
    );
    expect(from, DateTime(2026, 9, 28));
    expect(to, DateTime(2026, 10, 3));
    expect(id, 'RH-20260928-1003');
  });

  test('un mois : le mensuel du mois civil', () {
    final (id, from, to) = pointReport(
      EvolutionGranularity.month,
      DateTime(2026, 2, 1),
    );
    expect(from, DateTime(2026, 2));
    expect(to, DateTime(2026, 2, 28));
    expect(id, 'RM-20260201-0228');
  });
}
