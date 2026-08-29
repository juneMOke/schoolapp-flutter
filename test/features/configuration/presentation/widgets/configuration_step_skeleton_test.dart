import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_skeleton.dart';
import 'package:school_app_flutter/features/configuration/presentation/bloc/configuration_bloc.dart';
import 'package:school_app_flutter/features/configuration/presentation/widgets/configuration_step_skeleton.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

const _label = 'Chargement des données de l\'étape';

void main() {
  Future<void> pump(WidgetTester tester, ConfigurationStep step) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('fr'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConfigurationStepSkeleton(step: step),
          ),
        ),
      ),
    );
    // Un seul `pump` : le pouls des squelettes tourne en boucle, et
    // `pumpAndSettle` n'aurait jamais de quoi s'arrêter.
    await tester.pump();
  }

  testWidgets('les CINQ étapes annoncent l\'attente', (tester) async {
    // La règle vaut pour tout le parcours. Portée par le seul squelette de
    // formulaire, l'annonce aurait manqué aux étapes 3, 4 et 5 — celles qui
    // attendent le plus longtemps, puisqu'elles attendent le serveur.
    final handle = tester.ensureSemantics();

    for (final step in ConfigurationStep.values) {
      await pump(tester, step);

      expect(
        tester.getSemantics(find.byType(ConfigurationStepSkeleton)),
        isSemantics(label: _label, isLiveRegion: true),
        reason: 'étape ${step.name}',
      );
    }

    handle.dispose();
  });

  testWidgets('aucune étape ne montre de spinner', (tester) async {
    for (final step in ConfigurationStep.values) {
      await pump(tester, step);

      expect(
        find.byType(CircularProgressIndicator),
        findsNothing,
        reason: 'étape ${step.name}',
      );
      expect(
        find.byType(EteeloSkeletonBox),
        findsWidgets,
        reason: 'étape ${step.name}',
      );
    }
  });

  testWidgets('les blocs ne se lisent pas un par un', (tester) async {
    // Sans l'exclusion, le lecteur d'écran parcourrait une vingtaine de
    // rectangles muets avant d'atteindre la seule phrase qui compte.
    final handle = tester.ensureSemantics();
    await pump(tester, ConfigurationStep.structure);

    expect(
      tester.getSemantics(find.byType(ConfigurationStepSkeleton)).childrenCount,
      0,
    );

    handle.dispose();
  });
}
