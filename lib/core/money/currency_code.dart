/// Les codes de devise qui circulent sur le fil, et leur mise en forme
/// canonique.
///
/// ## Pourquoi il n'y a pas d'enum ici
///
/// Le serveur ferme la liste (`USD`, `CDF`, `EUR`) et refuse le reste en 422 —
/// y compris, depuis la révision 3 du contrat, sur les champs qu'on **reçoit**.
/// La tentation est alors de fermer l'enum côté client aussi. Il ne faut pas.
///
/// Un `PaymentDelta` se lit **par lot** : une devise inconnue — celle que le
/// serveur ajoutera un jour, avant que cette version du client ne soit déployée
/// — ferait échouer la désérialisation du lot **entier**. De l'argent déjà
/// encaissé deviendrait invisible au pull, sur des tablettes qu'on ne met pas à
/// jour à la demande.
///
/// On normalise donc, et on ne rejette jamais. C'est la règle qui vaut déjà
/// pour `PaymentAnomalyKind.unknown` et `GeneratedDocumentDto.localDocType` :
/// un inconnu se traverse, il ne fait pas tomber la lecture.
abstract final class CurrencyCode {
  /// Dollar américain.
  static const String usd = 'USD';

  /// Franc congolais. S'écrit « FC » à l'affichage, `CDF` sur le fil.
  static const String cdf = 'CDF';

  /// Euro.
  static const String eur = 'EUR';

  /// Forme canonique d'un code : sans espaces autour, en majuscules.
  ///
  /// `' usd '` devient `'USD'`. Une chaîne vide **reste vide** : c'est un état
  /// réel du grand-livre local (une ligne dont la devise n'a jamais été
  /// renseignée), et la refuser ferait échouer une lecture.
  static String normalize(String raw) => raw.trim().toUpperCase();
}
