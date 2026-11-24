import 'package:school_app_flutter/features/academics/data/models/offline/grades_referential_rows.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/intitule_colonne.dart';

/// Les intitulés que la tablette tire, hors ligne, des motifs de la grille
/// d'un cours. Le seul calcul permis : `{n}` remplacé par le rang de la
/// sous-période dans l'année, ou par l'ordre de la période pour l'examen.
/// Aucun mot n'est choisi ici.
///
/// Sans grille (bundle d'avant la v88), rien n'est nommé et l'examen reste
/// « inconnu » : l'écran garde ses intitulés d'avant.
class GrilleIntitules {
  final RefGrilleRow? grille;

  /// Le cours n'a pas d'examen : maximum nul ou à 0 sur sa ligne de barème.
  final bool sansExamen;

  const GrilleIntitules({required this.grille, required this.sansExamen});

  IntituleColonne? sousPeriode(RefSousPeriodeRow sousPeriode) {
    final motifs = grille;
    final rang = sousPeriode.rang;
    if (motifs == null || rang == null) return null;
    return IntituleColonne.fromMotifs(
      motifs.intituleSousPeriode,
      motifs.intituleCourtSousPeriode,
      rang,
    );
  }

  ColonneExamen examen(int ordrePeriode) {
    final motifs = grille;
    if (motifs == null) return const ColonneExamen.inconnue();
    if (sansExamen) return const ColonneExamen.absente();
    final intitule = IntituleColonne.fromMotifs(
      motifs.intituleExamen,
      motifs.intituleCourtExamen,
      ordrePeriode,
    );
    return intitule == null
        ? const ColonneExamen.inconnue()
        : ColonneExamen.nommee(intitule);
  }
}
