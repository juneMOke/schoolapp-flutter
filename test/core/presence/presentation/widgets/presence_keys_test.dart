import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/presence/domain/presence_status.dart';
import 'package:school_app_flutter/core/presence/presentation/presence_row_view.dart';
import 'package:school_app_flutter/core/presence/presentation/widgets/presence_keys.dart';

class _Actions implements PresenceRowActions {
  final chosen = <PresenceStatus>[];
  var cleared = 0;

  @override
  void choose(PresenceStatus status) => chosen.add(status);

  @override
  void clear() => cleared++;

  @override
  void cycle() {}

  @override
  void retry() {}

  @override
  Future<void> editArrival() async {}

  @override
  Future<void> justify() async {}
}

/// L'appel au clavier : une touche par statut, les flèches d'une personne à
/// l'autre.
void main() {
  PresenceRowView person(String id, PresenceStatus status) => PresenceRowView(
    personId: id,
    firstName: 'Prénom',
    lastName: id,
    title: id,
    subtitle: '',
    status: status,
  );

  late _Actions first;
  late _Actions second;

  Future<void> pump(
    WidgetTester tester, {
    PresenceStatus status = PresenceStatus.none,
  }) async {
    first = _Actions();
    second = _Actions();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (final (id, actions) in [('a', first), ('b', second)])
                PresenceKeys(
                  row: person(id, status),
                  actions: actions,
                  child: InkWell(
                    key: Key(id),
                    onTap: () {},
                    child: SizedBox(height: 60, child: Text(id)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    Focus.of(tester.element(find.text('a'))).requestFocus();
    await tester.pump();
  }

  Future<void> type(WidgetTester tester, String character) async {
    await tester.sendKeyDownEvent(
      LogicalKeyboardKey(character.codeUnitAt(0)),
      character: character,
    );
    await tester.sendKeyUpEvent(LogicalKeyboardKey(character.codeUnitAt(0)));
    await tester.pump();
  }

  testWidgets('P, R, A posent le statut de la personne qui a le focus', (
    tester,
  ) async {
    await pump(tester);
    await type(tester, 'p');
    await type(tester, 'r');
    await type(tester, 'a');
    expect(first.chosen, [
      PresenceStatus.present,
      PresenceStatus.late,
      PresenceStatus.absent,
    ]);
    expect(second.chosen, isEmpty);
  });

  testWidgets('retaper le statut déjà posé ne l\'efface pas', (tester) async {
    await pump(tester, status: PresenceStatus.present);
    await type(tester, 'p');
    expect(first.chosen, isEmpty);
  });

  testWidgets('Suppr remet « à pointer »', (tester) async {
    await pump(tester, status: PresenceStatus.absent);
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();
    expect(first.cleared, 1);
  });

  testWidgets('↓ passe à la personne suivante', (tester) async {
    await pump(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await type(tester, 'a');
    expect(second.chosen, [PresenceStatus.absent]);
    expect(first.chosen, isEmpty);
  });
}
