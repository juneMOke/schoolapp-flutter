import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/menu_constants.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

class EnrollmentNavigationHelper {
  const EnrollmentNavigationHelper._();

  /// Quitte le wizard pour retrouver un listing d'inscription **à jour**.
  ///
  /// Le wizard s'ouvre par deux chemins qui n'ont PAS la même pile :
  ///  - `push` depuis une ligne de listing (reprise d'un brouillon, candidat
  ///    RE/PRE) : l'accueil est toujours sous la pile. Un `goNamed(home)` y
  ///    serait inerte — la clé de page GoRouter d'une route vaut son chemin
  ///    *matché* (`/home`), sans les query params : le `Navigator` réutilise la
  ///    page existante, `HomePage` n'est jamais remontée, son `subMenuId`
  ///    initial est ignoré, et TOUT le sous-arbre (NavigationBloc →
  ///    EnrollmentFeatureScope → EnrollmentLocalListBloc) garde son état — donc
  ///    la liste périmée, avec le dossier qu'on vient de finaliser encore badgé
  ///    « Brouillon ». Pire, l'attente du `push` ne s'achève jamais : le
  ///    `onDetailReturned` du listing ne se déclenche pas non plus. On dépile
  ///    donc, et le listing en dessous se re-lit (read-your-writes).
  ///  - `go` depuis le bouton de création (pile déclarative remplacée) : rien à
  ///    dépiler, l'accueil est reconstruit à neuf par la redirection.
  static void leaveWizardToListing(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    redirectToFirstRegistrationFromHome(context);
  }

  static void redirectToFirstRegistrationFromHome(BuildContext context) {
    context.goNamed(
      AppRoutesNames.home,
      queryParameters: {'subMenuId': MenuConstants.premiereInscriptionId},
    );
  }
}
