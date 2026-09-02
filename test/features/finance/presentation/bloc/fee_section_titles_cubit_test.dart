import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/configuration/domain/usecases/refresh_fee_section_titles_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_fee_section_titles_use_case.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';

class _MockGet extends Mock implements GetFeeSectionTitlesUseCase {}

class _MockRefresh extends Mock implements RefreshFeeSectionTitlesUseCase {}

/// Les titres de sections vus par l'écran (GF-2).
///
/// Lecture **traversante** : le local d'abord — la fiche s'affiche sans rien
/// attendre — puis le serveur, une fois par session, et seulement s'il rapporte
/// quelque chose de neuf.
void main() {
  late _MockGet get;
  late _MockRefresh refresh;

  setUp(() {
    get = _MockGet();
    refresh = _MockRefresh();
    when(() => refresh()).thenAnswer((_) async => const Right(0));
  });

  FeeSectionTitlesCubit build() =>
      FeeSectionTitlesCubit(getTitles: get, refreshTitles: refresh);

  test('sans chargement, aucun titre — et donc le repli', () {
    expect(build().state.titleOf('TUITION'), isNull);
  });

  test('indexe les titres par nature, insensible à la casse', () async {
    when(
      () => get(),
    ).thenAnswer((_) async => const Right({'TUITION': 'Frais scolaires'}));
    final cubit = build();

    await cubit.load();

    expect(cubit.state.titleOf('TUITION'), 'Frais scolaires');
    expect(cubit.state.titleOf('tuition'), 'Frais scolaires');
    expect(cubit.state.titleOf('CANTEEN'), isNull);
  });

  test('un titre vide vaut un titre absent', () async {
    when(() => get()).thenAnswer((_) async => const Right({'TUITION': ''}));
    final cubit = build();

    await cubit.load();

    expect(cubit.state.titleOf('TUITION'), isNull);
  });

  test(
    'un échec de lecture ne fait pas tomber l\'écran : table vide',
    () async {
      when(
        () => get(),
      ).thenAnswer((_) async => const Left(StorageFailure('illisible')));
      final cubit = build();

      await cubit.load();

      expect(cubit.state.titles, isEmpty);
    },
  );

  test('LE LOCAL EST ÉMIS AVANT toute tentative réseau', () async {
    // C'est ce qui rend l'écran utilisable hors ligne : la fiche s'affiche sans
    // attendre, et une tablette sans couverture n'attend rien du tout.
    final order = <String>[];
    when(() => get()).thenAnswer((_) async {
      order.add('local');
      return const Right({'TUITION': 'Frais scolaires'});
    });
    when(() => refresh()).thenAnswer((_) async {
      order.add('réseau');
      return const Right(0);
    });

    await build().load();

    expect(order.first, 'local');
  });

  test(
    'un rafraîchissement qui rapporte quelque chose relit le cache',
    () async {
      var reads = 0;
      when(() => get()).thenAnswer((_) async {
        reads++;
        return Right({'TUITION': 'Frais scolaires $reads'});
      });
      when(() => refresh()).thenAnswer((_) async => const Right(7));
      final cubit = build();

      await cubit.load();

      expect(reads, 2);
      expect(cubit.state.titleOf('TUITION'), 'Frais scolaires 2');
    },
  );

  test('un rafraîchissement SANS nouveauté ne relit rien', () async {
    // Le titre ne doit pas re-clignoter à chaque montage : `0` couvre la session
    // déjà tirée, l'école non résolue, et le catalogue vide.
    when(
      () => get(),
    ).thenAnswer((_) async => const Right({'TUITION': 'Frais scolaires'}));
    when(() => refresh()).thenAnswer((_) async => const Right(0));

    await build().load();

    verify(() => get()).called(1);
  });

  test('un rafraîchissement en ÉCHEC laisse le local affiché', () async {
    when(
      () => get(),
    ).thenAnswer((_) async => const Right({'TUITION': 'Frais scolaires'}));
    when(
      () => refresh(),
    ).thenAnswer((_) async => const Left(NetworkFailure('hors ligne')));
    final cubit = build();

    await cubit.load();

    expect(
      cubit.state.titleOf('TUITION'),
      'Frais scolaires',
      reason:
          'Un titre d\'hier vaut mieux qu\'un écran qui se renomme parce que '
          'le réseau a manqué.',
    );
  });
}
