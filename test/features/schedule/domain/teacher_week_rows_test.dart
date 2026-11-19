import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_grid.dart';
import 'package:school_app_flutter/features/schedule/domain/entities/time_slot.dart';
import 'package:school_app_flutter/features/schedule/domain/services/slot_overlap.dart';
import 'package:school_app_flutter/features/schedule/domain/services/teacher_week_rows.dart';

GridTimeSlot slot(String id, int order, String s, String e, String? grid) =>
    GridTimeSlot(
      TimeSlot(id: id, order: order, startTime: s, endTime: e),
      grid,
    );

void main() {
  final slots = [
    slot('s1', 1, '07:30:00', '08:20:00', 'sec'),
    slot('s2', 2, '08:20:00', '09:10:00', 'sec'),
    slot('p1', 1, '07:45:00', '08:35:00', 'pri'),
    slot('p2', 2, '08:35:00', '09:25:00', 'pri'),
    slot('x1', 1, '07:00:00', '07:30:00', 'other'),
  ];
  const grids = {
    'sec': TimeGrid(
      id: 'sec',
      name: 'Secondaire',
      recess: MinuteRange(550, 570),
    ),
    'pri': TimeGrid(id: 'pri', name: 'Primaire'),
  };

  test('deux grilles : rangées par heure, grille inutilisée écartée', () {
    final rows = TeacherWeekRows.compose(
      slots: slots,
      usedSlotIds: {'s2', 'p1'},
      grids: grids,
    );
    expect(rows.map((r) => r.id), ['s1', 'p1', 's2', 'p2', 'recess:sec']);
    final recess = rows.last;
    expect(recess.isBreak, isTrue);
    expect(recess.startTime, '09:10:00');
    expect(recess.label, 'Secondaire');
  });

  test('sans séance : tous les créneaux, sans récréation inventée', () {
    final rows = TeacherWeekRows.compose(
      slots: slots,
      usedSlotIds: const {},
      grids: grids,
    );
    expect(rows, hasLength(5));
    expect(rows.first.id, 'x1');
  });

  test('une récréation déjà portée par un créneau n’est pas doublée', () {
    final rows = TeacherWeekRows.compose(
      slots: [...slots, slot('rec', 3, '09:10:00', '09:30:00', 'sec')],
      usedSlotIds: {'s1'},
      grids: grids,
    );
    expect(rows.where((r) => r.isBreak), isEmpty);
  });

  test('la grille d’un cycle : par code, sinon par défaut', () {
    const all = [
      TimeGrid(id: 'g1', name: 'École', isDefault: true),
      TimeGrid(id: 'g2', name: 'Primaire', cycleCodes: ['PRI']),
    ];
    expect(TimeGrid.forCycle('PRI', all)!.id, 'g2');
    expect(TimeGrid.forCycle('SEC', all)!.id, 'g1');
  });

  test('la grille et la vue Jour rangent par heure, pas par numéro', () {
    const rows = [
      TimeSlot(id: 'b', order: 1, startTime: '07:45:00', endTime: '08:35:00'),
      TimeSlot(
        id: 'r',
        order: -1,
        startTime: '09:10:00',
        endTime: '09:30:00',
        isBreak: true,
      ),
      TimeSlot(id: 'a', order: 2, startTime: '07:30:00', endTime: '08:20:00'),
    ];
    final sorted = [...rows]..sort(TimeSlot.compareByTime);
    expect(sorted.map((s) => s.id), ['a', 'b', 'r']);
  });
}
