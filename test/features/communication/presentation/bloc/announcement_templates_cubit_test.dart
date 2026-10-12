import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_template.dart';
import 'package:school_app_flutter/features/communication/domain/repositories/announcement_template_repository.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/pending_announcement_seed.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/templates/announcement_templates_cubit.dart';

class _MockRepository extends Mock implements AnnouncementTemplateRepository {}

const _a = AnnouncementTemplate(
  id: 'a',
  category: AnnouncementCategory.info,
  title: 'Réunion',
  body: 'Réunion le [date].',
);
const _b = AnnouncementTemplate(
  id: 'b',
  category: AnnouncementCategory.administrative,
  title: 'Rappel',
  body: 'Il reste {montant}.',
);

void main() {
  late _MockRepository repo;
  late AnnouncementTemplatesCubit cubit;

  setUpAll(() => registerFallbackValue(_a));
  setUp(() async {
    repo = _MockRepository();
    when(() => repo.list()).thenAnswer((_) async => const Right([_a]));
    cubit = AnnouncementTemplatesCubit(repo);
    await cubit.load();
  });

  test('créer : en tête de grille', () async {
    when(
      () => repo.create(
        category: AnnouncementCategory.administrative,
        title: 'Rappel',
        body: 'Il reste {montant}.',
      ),
    ).thenAnswer((_) async => const Right(_b));
    final failure = await cubit.create(
      category: AnnouncementCategory.administrative,
      title: 'Rappel',
      body: 'Il reste {montant}.',
    );
    expect(failure, isNull);
    expect(cubit.state.items, [_b, _a]);
  });

  test('modifier : remplacé en place', () async {
    const edited = AnnouncementTemplate(
      id: 'a',
      category: AnnouncementCategory.event,
      title: 'Réunion',
      body: 'x',
    );
    when(() => repo.update(any())).thenAnswer((_) async => const Right(edited));
    await cubit.update(edited);
    expect(cubit.state.items, [edited]);
  });

  test('supprimer : retiré ; un échec est rendu, la grille intacte', () async {
    when(
      () => repo.delete('a'),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    expect(await cubit.delete('a'), const NetworkFailure());
    expect(cubit.state.items, [_a]);
    when(() => repo.delete('a')).thenAnswer((_) async => const Right(unit));
    expect(await cubit.delete('a'), isNull);
    expect(cubit.state.items, isEmpty);
  });

  test('le brouillon d\'un modèle ne s\'ouvre qu\'une fois', () {
    final pending = PendingAnnouncementSeed(owner: () => 'u');
    const seed = AnnouncementContent(title: 'Réunion');
    pending.request(seed);
    expect(pending.take(), seed);
    expect(pending.take(), isNull);
  });
}
