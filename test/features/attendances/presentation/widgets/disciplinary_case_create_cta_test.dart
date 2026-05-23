import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_create_cta.dart';

void main() {
  testWidgets('renders CTA content and triggers action on tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DisciplinaryCaseCreateCta(
            onPressed: () => tapped = true,
            label: 'Nouveau cas',
            subtitle: 'Documentez un incident disciplinaire.',
          ),
        ),
      ),
    );

    expect(find.text('Nouveau cas'), findsOneWidget);
    expect(find.text('Documentez un incident disciplinaire.'), findsOneWidget);
    expect(find.byIcon(Icons.add_task_outlined), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

    await tester.tap(find.byType(DisciplinaryCaseCreateCta));
    await tester.pump();

    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });
}
