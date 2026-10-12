import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_template.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_template_repository.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/templates/announcement_templates_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/templates/template_form_dialog.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/templates/templates_screen.dart';

import '../../communication_fixtures.dart';

class _MockRepository extends Mock implements AnnouncementTemplateRepository {}

const _reminder = AnnouncementTemplate(
  id: 't-1',
  category: AnnouncementCategory.administrative,
  title: 'Rappel de paiement',
  body: 'Chers parents de {eleve} ({classe}), il reste {montant}.',
);

void main() {
  late _MockRepository repo;

  setUp(() {
    repo = _MockRepository();
    when(() => repo.list()).thenAnswer((_) async => const Right([_reminder]));
  });

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      communicationHost(
        BlocProvider(
          create: (_) => AnnouncementTemplatesCubit(repo)..load(),
          child: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('gestion : la carte, ses champs et ses trois gestes', (
    tester,
  ) async {
    AnnouncementTemplate? used;
    await pump(
      tester,
      TemplatesScreen(
        onUse: (t) => used = t,
        onCreate: () {},
        onEdit: (_) {},
        onDelete: (_) {},
      ),
    );
    expect(find.text('Rappel de paiement'), findsOneWidget);
    expect(find.text("Nom de l'élève"), findsOneWidget);
    expect(find.text('Montant dû'), findsOneWidget);
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
    await tester.tap(find.text('Utiliser'));
    expect(used, _reminder);
  });

  testWidgets('choix depuis la liste : Utiliser seulement, et le retour', (
    tester,
  ) async {
    await pump(tester, TemplatesScreen(onUse: (_) {}, onBack: () {}));
    expect(find.text("Partir d'un modèle"), findsOneWidget);
    expect(find.text('Utiliser'), findsOneWidget);
    expect(find.text('Modifier'), findsNothing);
    expect(find.text('Créer un modèle'), findsNothing);
  });

  testWidgets('aucun modèle : en créer un', (tester) async {
    when(() => repo.list()).thenAnswer((_) async => const Right([]));
    var created = 0;
    await pump(tester, TemplatesScreen(onCreate: () => created++));
    expect(find.text("Aucun modèle pour l'instant"), findsOneWidget);
    await tester.tap(find.text('Créer un modèle').last);
    expect(created, 1);
  });

  testWidgets('la modale exige titre et message, puis enregistre', (
    tester,
  ) async {
    final saved = <String>[];
    await pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => showTemplateFormDialog(
            context,
            onSave: (category, title, body) async {
              saved.add('$title|$body');
              return null;
            },
          ),
          child: const Text('ouvrir'),
        ),
      ),
    );
    await tester.tap(find.text('ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Donnez un titre au communiqué.'), findsOneWidget);
    expect(saved, isEmpty);

    final fields = find.byType(EditableText);
    await tester.enterText(fields.at(0), 'Réunion');
    await tester.enterText(fields.at(1), 'Réunion le [date].');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(saved, ['Réunion|Réunion le [date].']);
    expect(find.text('Enregistrer'), findsNothing);
  });

  testWidgets('lecture en échec : les quatre familles', (tester) async {
    when(
      () => repo.list(),
    ).thenAnswer((_) async => const Left(UnauthorizedFailure()));
    await pump(tester, const TemplatesScreen());
    expect(find.text('Accès refusé'), findsOneWidget);
  });
}
