import 'package:equatable/equatable.dart';

/// Le nom d'une colonne de notes, tel que la grille de la classe le donne :
/// « Étape 3 » en toutes lettres, « É3 » en en-tête étroit. Une donnée de
/// l'école, dans la langue de son bulletin : elle ne passe jamais par les
/// fichiers de traduction, et le front ne la fabrique pas.
class IntituleColonne extends Equatable {
  final String libelle;
  final String libelleCourt;

  const IntituleColonne({required this.libelle, required this.libelleCourt});

  /// `null` si les deux sont vides ; un seul des deux sert pour les deux.
  static IntituleColonne? of(String? libelle, String? libelleCourt) {
    final long = _clean(libelle);
    final court = _clean(libelleCourt);
    if (long == null && court == null) return null;
    return IntituleColonne(
      libelle: long ?? court!,
      libelleCourt: court ?? long!,
    );
  }

  /// Hors ligne : le motif de la grille (« Étape {n} ») et le numéro de la
  /// colonne. C'est le seul calcul permis ; aucun mot n'est choisi ici.
  static IntituleColonne? fromMotifs(
    String? motif,
    String? motifCourt,
    int numero,
  ) => of(_fill(motif, numero), _fill(motifCourt, numero));

  static String? _fill(String? motif, int numero) =>
      motif?.replaceAll('{n}', '$numero');

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  @override
  List<Object?> get props => [libelle, libelleCourt];
}

/// Ce que le serveur dit de l'examen d'une période. Trois cas, que le fil
/// distingue par la présence du champ :
/// - [ColonneExamen.nommee] : il existe, avec son nom ;
/// - [ColonneExamen.absente] : le champ vaut `null`, aucun examen ;
/// - [ColonneExamen.inconnue] : le champ manque (serveur plus ancien), l'écran
///   garde son comportement d'avant.
class ColonneExamen extends Equatable {
  final bool exists;
  final IntituleColonne? intitule;

  const ColonneExamen.nommee(IntituleColonne this.intitule) : exists = true;

  const ColonneExamen.absente() : exists = false, intitule = null;

  const ColonneExamen.inconnue() : exists = true, intitule = null;

  @override
  List<Object?> get props => [exists, intitule];
}
