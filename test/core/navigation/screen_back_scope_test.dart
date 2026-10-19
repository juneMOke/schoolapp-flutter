import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/navigation/screen_back_registry.dart';
import 'package:school_app_flutter/core/navigation/screen_back_scope.dart';

/// Un écran à niveaux remonte d'un niveau au retour système — par le
/// registre de la coquille s'il y en a un, par un `PopScope` sinon.
void main() {
  testWidgets('sans registre : un PopScope remonte d\'un niveau', (
    tester,
  ) async {
    var backs = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ScreenBackScope(
          canPop: false,
          onBack: () => backs++,
          child: const SizedBox(),
        ),
      ),
    );

    await tester.binding.handlePopRoute();

    expect(backs, 1);
  });

  testWidgets('sous un registre : pas de PopScope, le registre décide', (
    tester,
  ) async {
    final registry = ScreenBackRegistry();
    final backs = <String>[];
    Widget scopes({required bool innerCanPop}) => MaterialApp(
      home: ScreenBackRegistryScope(
        registry: registry,
        child: ScreenBackScope(
          canPop: false,
          onBack: () => backs.add('écran'),
          child: ScreenBackScope(
            canPop: innerCanPop,
            onBack: () => backs.add('niveau'),
            child: const SizedBox(),
          ),
        ),
      ),
    );

    await tester.pumpWidget(scopes(innerCanPop: false));
    expect(find.byType(PopScope<Object?>), findsNothing);

    // Le plus récent d'abord.
    expect(registry.handleBack(), isTrue);
    expect(backs, ['niveau']);

    // Un niveau au repos laisse la main à l'écran qui le porte.
    await tester.pumpWidget(scopes(innerCanPop: true));
    expect(registry.handleBack(), isTrue);
    expect(backs, ['niveau', 'écran']);

    // Démonté, il se désinscrit.
    await tester.pumpWidget(const SizedBox());
    expect(registry.handleBack(), isFalse);
  });
}
