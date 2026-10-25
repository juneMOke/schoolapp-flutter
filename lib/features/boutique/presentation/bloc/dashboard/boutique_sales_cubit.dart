import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/article_family.dart';
import 'package:school_app_flutter/core/entities/dashboard_window.dart';
import 'package:school_app_flutter/features/boutique/domain/entities/dashboard/sales_query.dart';
import 'package:school_app_flutter/features/boutique/domain/usecases/get_boutique_sales_use_case.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_sales_state.dart';

export 'package:school_app_flutter/features/boutique/presentation/bloc/dashboard/boutique_sales_state.dart';

/// « Ventes de la période » — toutes les ventes de la fenêtre du tableau de
/// bord, 10 par page, filtrées par type d'article **ou** par classe.
///
/// Son propre état, comme « Élèves concernés » : un filtre ou une page
/// rechargent la carte seule.
class BoutiqueSalesCubit extends Cubit<BoutiqueSalesState> {
  final GetBoutiqueSalesUseCase _getSales;

  String _academicYearId = '';
  DashboardWindow? _window;

  /// Le numéro de la dernière lecture : une réponse dépassée par un geste
  /// posé depuis est jetée.
  int _ticket = 0;

  BoutiqueSalesCubit({required GetBoutiqueSalesUseCase getSales})
    : _getSales = getSales,
      super(const BoutiqueSalesState());

  Future<void> start({
    required String academicYearId,
    required DashboardWindow window,
  }) {
    _academicYearId = academicYearId;
    _window = window;
    return _load(page: 0);
  }

  /// La période a changé : le filtre reste, la liste repart de la page 1.
  Future<void> windowChanged(DashboardWindow window) async {
    if (window == _window) return;
    _window = window;
    await _load(page: 0);
  }

  /// Bascule de mode : le critère de l'autre mode tombe, puisqu'il ne
  /// partirait plus. La liste ne se relit que si un critère était posé.
  Future<void> modeChanged(SalesFilterMode mode) async {
    if (mode == state.mode) return;
    final hadFilter = state.hasFilter;
    emit(
      state.copyWith(
        mode: mode,
        family: null,
        classId: null,
        selectedClassLabel: null,
      ),
    );
    if (hadFilter) await _load(page: 0);
  }

  Future<void> familySelected(ArticleFamily? family) async {
    if (family == state.family) return;
    emit(state.copyWith(mode: SalesFilterMode.family, family: family));
    await _load(page: 0);
  }

  Future<void> classSelected(String? classId) async {
    if (classId == state.classId) return;
    String? label;
    for (final c in state.page?.classes ?? const []) {
      if (c.id == classId) label = c.label;
    }
    emit(
      state.copyWith(
        mode: SalesFilterMode.classroom,
        classId: classId,
        selectedClassLabel: label,
      ),
    );
    await _load(page: 0);
  }

  Future<void> resetFilter() async {
    if (!state.hasFilter) return;
    emit(state.copyWith(family: null, classId: null, selectedClassLabel: null));
    await _load(page: 0);
  }

  /// [page] 0-based.
  Future<void> pageChanged(int page) async {
    final current = state.page;
    if (current == null || page < 0 || page >= current.totalPages) return;
    if (page == current.page) return;
    await _load(page: page, keepPage: true);
  }

  /// Rejoue la dernière question — page et filtre compris.
  Future<void> retry() => _load(page: state.query?.page ?? 0);

  /// [keepPage] : un changement de page garde la page affichée, la barre dit
  /// l'attente. Une autre question (période, filtre) la retire : l'ancienne
  /// liste se lirait comme la réponse à la nouvelle.
  Future<void> _load({required int page, bool keepPage = false}) async {
    final window = _window;
    if (window == null) return;
    final ticket = ++_ticket;
    final query = SalesQuery(
      academicYearId: _academicYearId,
      window: window,
      family: state.mode == SalesFilterMode.family ? state.family : null,
      classId: state.mode == SalesFilterMode.classroom ? state.classId : null,
      page: page,
    );
    emit(
      state.copyWith(
        status: SalesStatus.loading,
        failure: null,
        page: keepPage ? state.page : null,
      ),
    );
    final result = await _getSales(query);
    if (isClosed || ticket != _ticket) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: SalesStatus.failure,
          failure: failure,
          page: null,
          query: query,
        ),
      ),
      (salesPage) => emit(
        state.copyWith(
          status: SalesStatus.ready,
          page: salesPage,
          query: query,
        ),
      ),
    );
  }
}
