import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/school_ticket_copies_select.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

Widget _host(int? value, {ValueChanged<int>? onChanged}) => MaterialApp(
  locale: const Locale('fr'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: SchoolTicketCopiesSelect(
      value: value,
      onChanged: onChanged ?? (_) {},
    ),
  ),
);

void main() {
  /// Une école qui n'a rien choisi voit ce qui sortira, pas une case vide.
  testWidgets('sans réglage, le défaut est dit', (tester) async {
    await tester.pumpWidget(_host(null));

    expect(find.text('1 (par défaut)'), findsOne);
  });

  testWidgets('le réglage enregistré est affiché', (tester) async {
    await tester.pumpWidget(_host(3));

    expect(find.text('3'), findsOne);
    expect(find.text('1 (par défaut)'), findsNothing);
  });

  /// Une valeur que la liste ne propose pas n'est jamais montrée comme
  /// choisie : on retombe sur le défaut.
  testWidgets('une valeur hors bornes montre le défaut', (tester) async {
    await tester.pumpWidget(_host(9));

    expect(find.text('1 (par défaut)'), findsOne);
  });
}
