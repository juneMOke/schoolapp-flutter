import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Ce que le percepteur **désigne** pendant sa séance : les élèves cochés, et
/// ceux qu'il a marqués « à renvoyer ».
///
/// Deux ensembles, deux durées de vie :
///
///  - [selected] n'a de sens que dans son périmètre. Changer de frais, de
///    classe, de situation ou de plancher la vide — une sélection faite sur une
///    population n'en désigne pas une autre.
///  - [marked] traverse au contraire les classes : c'est **en les parcourant**
///    qu'on constitue la liste. Elle survit aux filtres, aux erreurs et aux
///    allers-retours, et se perd à la sortie du module.
///
/// ⚠️ **Rien n'est écrit nulle part.** C'est un brouillon de séance, pas une
/// donnée : aucune persistance, aucun envoi, aucune trace au dossier. Un renvoi
/// effectif passe par le dossier d'inscription, élève par élève.
class FeeControlSelectionState extends Equatable {
  final Set<String> selected;
  final Set<String> marked;

  const FeeControlSelectionState({
    this.selected = const <String>{},
    this.marked = const <String>{},
  });

  bool get hasSelection => selected.isNotEmpty;

  bool get hasMarks => marked.isNotEmpty;

  @override
  List<Object?> get props => [selected, marked];
}

class FeeControlSelectionCubit extends Cubit<FeeControlSelectionState> {
  FeeControlSelectionCubit() : super(const FeeControlSelectionState());

  void toggle(String studentId) {
    final next = Set<String>.from(state.selected);
    if (!next.remove(studentId)) next.add(studentId);
    emit(FeeControlSelectionState(selected: next, marked: state.marked));
  }

  /// Coche **toute la page visible**, ou la décoche si elle l'est déjà en
  /// entier. Le geste ne porte jamais au-delà des lignes affichées : cocher
  /// vingt et un élèves d'un clic sur une page qui en montre dix ferait signer
  /// une liste qu'on n'a pas lue.
  void togglePage(Iterable<String> pageIds) {
    final ids = pageIds.toSet();
    if (ids.isEmpty) return;
    final next = Set<String>.from(state.selected);
    if (ids.every(next.contains)) {
      next.removeAll(ids);
    } else {
      next.addAll(ids);
    }
    emit(FeeControlSelectionState(selected: next, marked: state.marked));
  }

  void clearSelection() {
    if (state.selected.isEmpty) return;
    emit(FeeControlSelectionState(marked: state.marked));
  }

  /// Marque en lot, et **vide la sélection** : le geste est consommé.
  ///
  /// Additif : marquer deux fois les mêmes élèves n'empile rien.
  void mark(Iterable<String> studentIds) {
    emit(FeeControlSelectionState(marked: {...state.marked, ...studentIds}));
  }

  /// Bascule un seul élève — le geste du pied de fiche.
  void toggleMark(String studentId) {
    final next = Set<String>.from(state.marked);
    if (!next.remove(studentId)) next.add(studentId);
    emit(FeeControlSelectionState(selected: state.selected, marked: next));
  }

  void clearMarks() {
    if (state.marked.isEmpty) return;
    emit(FeeControlSelectionState(selected: state.selected));
  }
}
