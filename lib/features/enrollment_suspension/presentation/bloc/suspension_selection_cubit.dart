import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/helpers/selection_sets.dart';

/// Le mode « Désactiver des élèves » d'une liste : actif ou non, et les
/// inscriptions cochées. La sélection survit au changement de page (clé =
/// inscription) ; elle se vide à l'annulation et après le geste.
class SuspensionSelectionState extends Equatable {
  final bool active;
  final Set<String> selected;

  const SuspensionSelectionState({
    this.active = false,
    this.selected = const <String>{},
  });

  @override
  List<Object?> get props => [active, selected];
}

class SuspensionSelectionCubit extends Cubit<SuspensionSelectionState> {
  SuspensionSelectionCubit() : super(const SuspensionSelectionState());

  void start() => emit(const SuspensionSelectionState(active: true));

  /// Sort du mode sélection : « Annuler », ou le geste fait.
  void cancel() => emit(const SuspensionSelectionState());

  void toggle(String enrollmentId) {
    if (!state.active) return;
    emit(
      SuspensionSelectionState(
        active: true,
        selected: SelectionSets.toggled(state.selected, enrollmentId),
      ),
    );
  }

  /// Ne garde que les inscriptions encore dans les résultats : une nouvelle
  /// recherche ne laisse aucun élève coché qu'on ne voit plus.
  void retain(Set<String> visibleIds) {
    if (!state.active) return;
    final kept = state.selected.intersection(visibleIds);
    if (kept.length == state.selected.length) return;
    emit(SuspensionSelectionState(active: true, selected: kept));
  }

  /// Coche les éligibles de la page, ou les décoche s'ils l'étaient tous.
  void togglePage(Iterable<String> eligiblePageIds) {
    if (!state.active || eligiblePageIds.isEmpty) return;
    emit(
      SuspensionSelectionState(
        active: true,
        selected: SelectionSets.pageToggled(state.selected, eligiblePageIds),
      ),
    );
  }
}
