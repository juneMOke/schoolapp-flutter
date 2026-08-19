import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';

/// [AppBreakpoints.guardianSearchPinnedFormMinWidth] est une valeur DÉRIVÉE :
/// la largeur de dialogue à laquelle le `Wrap` des critères tient deux colonnes.
/// Elle ne peut pas se calculer là où elle est déclarée — `app_dimensions.dart`
/// importe `app_breakpoints.dart`, l'inverse ferait un cycle — donc c'est ce
/// test qui la tient alignée sur ses tokens.
///
/// Ce qu'il empêche : la valeur avait été arrondie à 460 au lieu de 464, ce qui
/// laissait une bande de quatre dp où les critères restaient figés alors que le
/// `Wrap` était retombé à une seule colonne. La modale y débordait de 74 dp —
/// exactement le défaut que le seuil existe pour fermer. Aucun test par tailles
/// d'appareil ne pouvait le voir : la bande est trop étroite pour être touchée
/// par un balayage au pas usuel.
void main() {
  test('le seuil vaut la largeur à laquelle le Wrap tient deux colonnes', () {
    const deuxColonnes =
        2 * AppDimensions.guardianSearchCriterionWidth + // les deux champs
        AppDimensions.spacingM + // la gouttière du Wrap
        2 * AppDimensions.spacingL; // la marge du bloc de critères

    expect(
      AppBreakpoints.guardianSearchPinnedFormMinWidth,
      deuxColonnes,
      reason:
          'un token a bougé sans que le seuil suive : sous ce seuil le Wrap '
          'empile ses quatre critères et le bloc figé déborde la modale',
    );
  });

  test('le seuil laisse la place à deux colonnes, jamais à une seule', () {
    // Juste au seuil : le contenu offert au Wrap doit encore contenir deux
    // champs et leur gouttière.
    const offertAuSeuil =
        AppBreakpoints.guardianSearchPinnedFormMinWidth -
        2 * AppDimensions.spacingL;
    expect(
      offertAuSeuil,
      greaterThanOrEqualTo(
        2 * AppDimensions.guardianSearchCriterionWidth + AppDimensions.spacingM,
      ),
    );

    // Un dp en dessous : deux colonnes ne tiennent plus, et le seuil doit donc
    // avoir renvoyé les critères dans le défilement.
    const offertJusteEnDessous = offertAuSeuil - 1;
    expect(
      offertJusteEnDessous,
      lessThan(
        2 * AppDimensions.guardianSearchCriterionWidth + AppDimensions.spacingM,
      ),
    );
  });
}
