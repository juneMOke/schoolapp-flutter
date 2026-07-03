import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/resultats/domain/entities/resultat_eleve_ligne.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_labels.dart';

/// Champ de tri de la table de la vue classe.
enum ResultatsSortField { eleve, sousPeriode, moyenne }

/// Critère de tri courant de la table (spec §4).
///
/// Un tri `null` conserve l'ordre du backend (rang croissant, non classés en
/// fin). Quel que soit le tri, les **non classés restent toujours en fin**.
class ResultatsSort extends Equatable {
  final ResultatsSortField field;

  /// Index de la sous-période visée quand [field] == [ResultatsSortField.sousPeriode].
  final int sousPeriodeIndex;
  final bool ascending;

  const ResultatsSort({
    required this.field,
    this.sousPeriodeIndex = 0,
    required this.ascending,
  });

  @override
  List<Object?> get props => [field, sousPeriodeIndex, ascending];
}

/// Trie [lignes] selon [sort] en gardant les non classés en fin. `null` →
/// ordre du backend (déjà trié). Ne mute pas [lignes].
List<ResultatEleveLigne> applyResultatsSort(
  List<ResultatEleveLigne> lignes,
  ResultatsSort? sort,
) {
  if (sort == null) {
    return lignes;
  }

  final classed = lignes.where((l) => !l.nonClasse).toList();
  final unclassed = lignes.where((l) => l.nonClasse).toList();

  int compare(ResultatEleveLigne a, ResultatEleveLigne b) {
    if (sort.field == ResultatsSortField.eleve) {
      final raw = _compareNames(a, b);
      return sort.ascending ? raw : -raw;
    }
    final va = sort.field == ResultatsSortField.moyenne
        ? a.moyenneGroupe
        : _pourcentageAt(a, sort.sousPeriodeIndex);
    final vb = sort.field == ResultatsSortField.moyenne
        ? b.moyenneGroupe
        : _pourcentageAt(b, sort.sousPeriodeIndex);
    // `null` (non noté) toujours en fin, indépendamment du sens de tri.
    if (va == null && vb == null) {
      return 0;
    }
    if (va == null) {
      return 1;
    }
    if (vb == null) {
      return -1;
    }
    final raw = va.compareTo(vb);
    return sort.ascending ? raw : -raw;
  }

  classed.sort(compare);
  return [...classed, ...unclassed];
}

int _compareNames(ResultatEleveLigne a, ResultatEleveLigne b) {
  final an = resultatsShortName(a.prenom, a.nom).toLowerCase();
  final bn = resultatsShortName(b.prenom, b.nom).toLowerCase();
  return an.compareTo(bn);
}

double? _pourcentageAt(ResultatEleveLigne ligne, int index) {
  if (index < 0 || index >= ligne.pourcentages.length) {
    return null;
  }
  return ligne.pourcentages[index].pourcentage;
}
