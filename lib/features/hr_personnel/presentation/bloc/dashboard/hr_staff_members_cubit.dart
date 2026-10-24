import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_category_key.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_roster_query.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/usecases/hr_staff_dashboard_use_cases.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_members_state.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/helpers/hr_location_filters.dart';

export 'package:school_app_flutter/features/hr_personnel/presentation/bloc/dashboard/hr_staff_members_state.dart';

/// « Qui sont-ils » — la liste nominative du personnel, filtrée, triée et
/// découpée **par le serveur**, 20 par page.
///
/// Un critère changé repart de la première page ; la recherche attend la fin
/// de la frappe ([debounce]) pour ne pas tirer une page par lettre.
class HrStaffMembersCubit extends Cubit<HrStaffMembersState> {
  static const defaultDebounce = Duration(milliseconds: 300);

  final GetHrStaffMembersUseCase _getMembers;
  final Duration debounce;

  Timer? _timer;

  /// Le numéro de la dernière lecture : une réponse dépassée par un geste
  /// posé depuis est jetée.
  int _ticket = 0;

  /// La page **demandée** en dernier — pas forcément celle affichée : une
  /// relecture de fond pendant un changement de page doit relire la page
  /// voulue, et « Réessayer » rejouer celle qui a échoué.
  int _requestedPage = 0;

  HrStaffMembersCubit({
    required GetHrStaffMembersUseCase getMembers,
    this.debounce = defaultDebounce,
  }) : _getMembers = getMembers,
       super(const HrStaffMembersState());

  Future<void> load() => _load(page: 0);

  void setText(String text) {
    if (text == state.query.text) return;
    emit(state.copyWith(query: state.query.withText(text)));
    _timer?.cancel();
    _timer = Timer(debounce, () => unawaited(_load(page: 0)));
  }

  Future<void> setCategory(HrCategoryKey? category) =>
      _ask(state.query.withCategory(category));

  /// Un second tap sur la catégorie active la retire.
  Future<void> toggleCategory(HrCategoryKey category) =>
      _ask(state.query.toggleCategory(category));

  Future<void> setSort(HrRosterSort sort) => _ask(state.query.withSort(sort));

  /// Vide la recherche et la catégorie ; garde l'ordre choisi.
  Future<void> clearFilters() => _ask(state.query.cleared());

  /// L'adresse a changé (F5, Précédent) : catégorie et ordre ; la recherche,
  /// qui n'y figure pas, reste.
  Future<void> applyLocation(HrLocationFilters filters) =>
      _ask(state.query.withCategory(filters.category).withSort(filters.sort));

  /// [page] à partir de 0.
  Future<void> pageChanged(int page) async {
    final current = state.page;
    if (current == null || page < 0 || page >= current.totalPages) return;
    if (page == current.page) return;
    await _load(page: page, keepPage: true);
  }

  /// Rejoue la dernière question, page comprise.
  Future<void> retry() => _load(page: _requestedPage);

  /// F5, fin d'un envoi : la page voulue relue, sans retirer de l'écran celle
  /// qui s'y trouve.
  Future<void> reload() =>
      _load(page: _requestedPage, keepPage: true, silent: true);

  Future<void> _ask(HrRosterQuery query) async {
    if (query == state.query && state.status != HrStaffMembersStatus.failure) {
      return;
    }
    _timer?.cancel();
    emit(state.copyWith(query: query));
    await _load(page: 0);
  }

  /// [keepPage] : la page affichée reste le temps de la lecture. [silent] :
  /// un échec la laisse aussi — une relecture ratée ne vide pas l'écran.
  Future<void> _load({
    required int page,
    bool keepPage = false,
    bool silent = false,
  }) async {
    final ticket = ++_ticket;
    _requestedPage = page;
    final query = state.query;
    emit(
      state.copyWith(
        status: HrStaffMembersStatus.loading,
        failure: null,
        page: keepPage ? state.page : null,
      ),
    );
    final result = await _getMembers(query, page: page);
    if (isClosed || ticket != _ticket) return;
    result.fold(
      (failure) {
        if (silent && state.page != null) {
          emit(state.copyWith(status: HrStaffMembersStatus.ready));
          return;
        }
        emit(
          state.copyWith(
            status: HrStaffMembersStatus.failure,
            failure: failure,
            page: null,
            answered: null,
          ),
        );
      },
      (members) {
        // La liste a raccourci sous la page voulue (une fiche sortie du
        // filtre, un agent retiré) : la dernière page qui existe, plutôt
        // qu'un « aucun agent » sous « 20 agents », sans barre pour revenir.
        if (members.items.isEmpty && page > 0 && members.totalElements > 0) {
          unawaited(
            _load(page: members.totalPages - 1, keepPage: true, silent: silent),
          );
          return;
        }
        emit(
          state.copyWith(
            status: HrStaffMembersStatus.ready,
            page: members,
            answered: query,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
