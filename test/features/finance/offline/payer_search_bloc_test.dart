import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_payer_identity.dart';
import 'package:school_app_flutter/features/finance/offline/domain/repositories/finance_offline_repository.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/get_payer_suggestions_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/search_payers_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_bloc.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_event.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payer_search_state.dart';

/// Repo de test : seules les deux lectures d'annuaire sont implémentées, le
/// reste du contrat n'entre pas dans ce bloc.
class _FakeRepo implements FinanceOfflineRepository {
  Either<Failure, List<LocalPayerIdentity>> suggestions = const Right([]);
  Either<Failure, List<LocalPayerIdentity>> results = const Right([]);

  /// Retient la lecture des suggestions jusqu'à ce que le test la libère.
  /// Sans elle, la lecture se résout dans la micro-tâche suivante et les deux
  /// événements se déroulent l'un APRÈS l'autre : il n'y a alors plus rien de
  /// concurrent à prouver.
  Completer<void>? suggestionsGate;

  @override
  Future<Either<Failure, List<LocalPayerIdentity>>> getPayerSuggestions(
    String studentId, {
    int limit = 8,
  }) async {
    await suggestionsGate?.future;
    return suggestions;
  }

  @override
  Future<Either<Failure, List<LocalPayerIdentity>>> searchPayers({
    String? lastName,
    String? firstName,
    String? surname,
    String? phoneNumber,
    int limit = 20,
  }) async => results;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('hors périmètre du bloc de recherche');
}

LocalPayerIdentity payer(String lastName, {PayerOrigin? origin}) =>
    LocalPayerIdentity(
      lastName: lastName,
      firstName: 'Joseph',
      phoneNumber: '+243816939060',
      origin: origin ?? PayerOrigin.previousPayment,
      paymentCount: 2,
    );

void main() {
  late _FakeRepo repo;

  PayerSearchBloc build() => PayerSearchBloc(
    suggestions: GetPayerSuggestionsUseCase(repo),
    search: SearchPayersUseCase(repo),
  );

  setUp(() => repo = _FakeRepo());

  blocTest<PayerSearchBloc, PayerSearchState>(
    'les suggestions arrivent marquées comme telles',
    setUp: () => repo.suggestions = Right([payer('Kabongo')]),
    build: build,
    act: (bloc) => bloc.add(const PayerSuggestionsRequested('s-1')),
    expect: () => [
      const PayerSearchLoading(),
      PayerSearchLoaded([payer('Kabongo')], isSuggestion: true),
    ],
  );

  /// Aucune suggestion ne vaut PAS « aucun résultat » : rien n'a été cherché.
  /// Sortir un état vide ferait croire à une recherche infructueuse, alors que
  /// l'élève n'a simplement pas encore d'historique.
  blocTest<PayerSearchBloc, PayerSearchState>(
    'aucune suggestion retombe sur l\'état initial, jamais sur le vide',
    build: build,
    act: (bloc) => bloc.add(const PayerSuggestionsRequested('s-1')),
    expect: () => [const PayerSearchLoading(), const PayerSearchInitial()],
  );

  blocTest<PayerSearchBloc, PayerSearchState>(
    'une recherche sans résultat sort l\'état vide',
    build: build,
    act: (bloc) => bloc.add(const PayerSearchRequested(lastName: 'Inconnu')),
    expect: () => [const PayerSearchLoading(), const PayerSearchEmpty()],
  );

  blocTest<PayerSearchBloc, PayerSearchState>(
    'les résultats de recherche ne sont pas marqués « suggestion »',
    setUp: () => repo.results = Right([payer('Mbayo')]),
    build: build,
    act: (bloc) => bloc.add(const PayerSearchRequested(lastName: 'Mbayo')),
    expect: () => [
      const PayerSearchLoading(),
      PayerSearchLoaded([payer('Mbayo')], isSuggestion: false),
    ],
  );

  blocTest<PayerSearchBloc, PayerSearchState>(
    'une base illisible se dit, elle ne se tait pas',
    setUp: () => repo.results = const Left(StorageFailure('base illisible')),
    build: build,
    act: (bloc) => bloc.add(const PayerSearchRequested(lastName: 'Mbayo')),
    expect: () => [
      const PayerSearchLoading(),
      const PayerSearchError('Erreur d\'accès à la base locale.'),
    ],
  );

  /// Le compteur de génération est PARTAGÉ entre suggestions et recherche : les
  /// suggestions partent à l'ouverture, et une recherche lancée pendant
  /// qu'elles courent encore doit les périmer. Sans ce partage, la liste des
  /// propositions écraserait le résultat que le guichetier vient de demander.
  blocTest<PayerSearchBloc, PayerSearchState>(
    'une recherche périme les suggestions encore en vol',
    setUp: () {
      repo.suggestions = Right([payer('Kabongo')]);
      repo.results = Right([payer('Mbayo')]);
      repo.suggestionsGate = Completer<void>();
    },
    build: build,
    act: (bloc) async {
      bloc.add(const PayerSuggestionsRequested('s-1'));
      bloc.add(const PayerSearchRequested(lastName: 'Mbayo'));
      // On rend la main à la boucle d'événements : la recherche a le temps
      // d'aboutir pendant que les suggestions sont encore retenues.
      await Future<void>.delayed(Duration.zero);
      repo.suggestionsGate!.complete();
    },
    // Un seul `Loading` : le bloc n'émet pas deux fois le même état. Ce qui
    // compte est la FIN de la liste — sans la garde de génération, les
    // suggestions arriveraient après et un troisième état
    // `PayerSearchLoaded(Kabongo, suggestion)` écraserait ce que le guichetier
    // vient de demander.
    expect: () => [
      const PayerSearchLoading(),
      PayerSearchLoaded([payer('Mbayo')], isSuggestion: false),
    ],
  );
}
