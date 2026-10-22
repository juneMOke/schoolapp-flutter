import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/beneficiaries_query.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_beneficiaries_use_case.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_catalog_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_beneficiaries_state.dart';

export 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_beneficiaries_state.dart';

/// « Élèves concernés » — qui a reçu quoi, sur la fenêtre du tableau de bord.
///
/// Son propre état, et c'est délibéré : changer un filtre recharge la carte
/// seule, sans démonter les chiffres au-dessus.
class BoutiqueBeneficiariesCubit extends Cubit<BoutiqueBeneficiariesState> {
  static const defaultDebounce = Duration(milliseconds: 300);

  final GetBoutiqueBeneficiariesUseCase _getBeneficiaries;
  final GetBoutiqueCatalogUseCase _getCatalog;
  final Duration debounce;

  String _academicYearId = '';
  DashboardWindow? _window;
  Timer? _timer;

  /// Le numéro de la dernière lecture : une réponse dépassée par un filtre
  /// posé depuis est jetée.
  int _ticket = 0;

  BoutiqueBeneficiariesCubit({
    required GetBoutiqueBeneficiariesUseCase getBeneficiaries,
    required GetBoutiqueCatalogUseCase getCatalog,
    this.debounce = defaultDebounce,
  }) : _getBeneficiaries = getBeneficiaries,
       _getCatalog = getCatalog,
       super(const BoutiqueBeneficiariesState());

  Future<void> start({
    required String academicYearId,
    required DashboardWindow window,
  }) async {
    _academicYearId = academicYearId;
    _window = window;
    await Future.wait([_loadArticleOptions(), _reload()]);
  }

  /// La période a changé : les filtres restent, la liste se relit.
  Future<void> windowChanged(DashboardWindow window) async {
    if (window == _window) return;
    _window = window;
    await _reload();
  }

  void searchChanged(String text) {
    if (text == state.search) return;
    _timer?.cancel();
    emit(state.copyWith(search: text));
    _timer = Timer(debounce, _reload);
  }

  /// Pose un article — depuis le menu, ou depuis le palmarès. [label] sert
  /// quand l'article n'est plus au catalogue.
  Future<void> articleSelected(String? articleId, {String? label}) {
    var options = state.articleOptions;
    if (articleId != null &&
        label != null &&
        !options.any((option) => option.id == articleId)) {
      options = [
        ...options,
        BeneficiaryArticleOption(id: articleId, label: label),
      ];
    }
    emit(state.copyWith(articleId: articleId, articleOptions: options));
    return _reload();
  }

  Future<void> classSelected(String? classId) {
    String? label;
    for (final c in state.page?.classes ?? const []) {
      if (c.id == classId) label = c.label;
    }
    emit(state.copyWith(classId: classId, selectedClassLabel: label));
    return _reload();
  }

  Future<void> resetFilters() {
    _timer?.cancel();
    emit(
      state.copyWith(
        articleId: null,
        classId: null,
        selectedClassLabel: null,
        search: '',
      ),
    );
    return _reload();
  }

  /// Rejoue la dernière question, filtres compris — après une coupure.
  Future<void> retry() => _reload();

  void toggleExpanded() => emit(state.copyWith(expanded: !state.expanded));

  Future<void> loadMore() async {
    final page = state.page;
    if (page == null || !page.hasMore || state.loadingMore) return;
    final ticket = _ticket;
    emit(state.copyWith(loadingMore: true));
    final result = await _getBeneficiaries(_query(page: page.page + 1));
    if (isClosed || ticket != _ticket) return;
    result.fold(
      // Une page suivante en échec ne vide pas ce qui est affiché.
      (_) => emit(state.copyWith(loadingMore: false)),
      (next) =>
          emit(state.copyWith(page: page.append(next), loadingMore: false)),
    );
  }

  Future<void> _reload() async {
    if (_window == null) return;
    final ticket = ++_ticket;
    emit(
      state.copyWith(
        status: BeneficiariesStatus.loading,
        failure: null,
        loadingMore: false,
      ),
    );
    final result = await _getBeneficiaries(_query());
    if (isClosed || ticket != _ticket) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: BeneficiariesStatus.failure, failure: failure),
      ),
      (page) =>
          emit(state.copyWith(status: BeneficiariesStatus.ready, page: page)),
    );
  }

  Future<void> _loadArticleOptions() async {
    final result = await _getCatalog(_academicYearId);
    if (isClosed) return;
    final catalog = result.fold((_) => null, (value) => value);
    if (catalog == null) return;
    final options = [
      for (final article in catalog.articles)
        BeneficiaryArticleOption(id: article.id, label: article.label),
    ]..sort((a, b) => a.label.compareTo(b.label));
    // Un article posé par le palmarès avant la fin de cette lecture reste.
    emit(
      state.copyWith(
        articleOptions: [
          ...options,
          for (final option in state.articleOptions)
            if (!options.any((o) => o.id == option.id)) option,
        ],
      ),
    );
  }

  BeneficiariesQuery _query({int page = 0}) => BeneficiariesQuery(
    academicYearId: _academicYearId,
    window: _window!,
    articleId: state.articleId,
    classId: state.classId,
    search: state.search,
    page: page,
  );

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
