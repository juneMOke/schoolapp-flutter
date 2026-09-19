import 'package:school_app_flutter/features/finance/domain/entities/finance_till/till_receipt.dart';
import 'package:school_app_flutter/features/finance/presentation/context/facturation_detail_intent.dart';

/// L'intention d'ouvrir la fiche de facturation depuis une ligne de caisse —
/// ou `null` quand la ligne n'a pas de quoi.
///
/// **Fonction pure, et c'est la raison de ce fichier.** La décision « cet œil
/// ouvre-t-il quelque chose, et sur quoi » se vérifie ici sans monter un widget,
/// sans routeur et sans BLoC. Sortie de l'arbre, elle cesse d'être un détail
/// d'implémentation d'une table : c'est la règle, et elle a ses propres tests.
///
/// ## Pourquoi `null` plutôt qu'un intent dégradé
///
/// `FacturationDetailIntent.invalid` existe et remplit les cinq champs
/// d'identité de chaînes vides. L'utiliser ici serait une faute : la fiche
/// rendrait alors « contexte indisponible » à la place du grand-livre, et l'œil
/// aurait promis une ouverture qui n'ouvre rien. Un `null` éteint le bouton en
/// amont, ce qui est la seule réponse honnête.
///
/// ## Les trois conditions
///
/// * [TillReceipt.canOpenFinancialRecord] — identifiant, nom et prénom sur la
///   ligne. Ils manquent ensemble quand l'annuaire ne résout plus l'élève, ou
///   tant que le serveur ne sert pas encore ces champs ;
/// * [academicYearId] non vide — il vient de **l'enveloppe** de la page, pas de
///   la ligne : c'est le paramètre sur lequel la requête a filtré, donc il vaut
///   pour les *n* lignes affichées.
///
/// Le **post-nom n'est pas une condition** : beaucoup d'élèves n'en ont pas, et
/// la fiche filtre les composants vides avant de composer le nom qu'elle
/// affiche. Le niveau et le cycle non plus — la caisse ne les porte pas, et la
/// fiche s'ouvre sans eux en affichant « Facturation · - » en sur-titre. Les
/// exiger avait déjà coûté une régression ailleurs : une carte d'erreur pour un
/// élève parfaitement identifié.
FacturationDetailIntent? tillReceiptRecordIntent(
  TillReceipt receipt, {
  required String? academicYearId,
}) {
  final year = academicYearId?.trim() ?? '';
  if (year.isEmpty || !receipt.canOpenFinancialRecord) return null;

  return FacturationDetailIntent(
    studentId: receipt.studentId!.trim(),
    academicYearId: year,
    firstName: receipt.firstName!.trim(),
    lastName: receipt.lastName!.trim(),
    // Le seul des trois qui peut manquer sans rien empêcher.
    surname: receipt.surname?.trim() ?? '',
    // La caisse ne sert ni niveau ni cycle : elle n'a qu'une classe en texte
    // libre, qui n'est ni l'un ni l'autre. Le sur-titre retombe sur « - »,
    // exactement comme pour une fiche ouverte depuis une recherche par nom.
    levelName: '',
    levelGroupName: '',
  );
}
