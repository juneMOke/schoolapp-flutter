/// Le commentaire de l'enseignant sur une note (V179), montré au parent sous
/// la note dès la publication.
///
/// Le serveur lit trois valeurs, et **seulement trois** :
/// - champ absent ou `null` : le commentaire existant est gardé ;
/// - chaîne vide (ou faite d'espaces) : il est retiré ;
/// - texte : il remplace le précédent.
///
/// Le piège est un champ de saisie vide qui partirait en `""` et effacerait un
/// commentaire. [NoteCommentaire.edit] ne produit donc `""` que si l'enseignant
/// a vidé un commentaire qui existait.
abstract final class NoteCommentaire {
  /// 1 000 caractères au plus, espaces de bord retirés ; au-delà, le serveur
  /// refuse la ligne (pas le lot).
  static const int maxLength = 1000;

  /// La valeur à envoyer quand l'enseignant passe de [previous] à [typed] :
  /// `null` si rien ne change, `""` pour retirer, le texte rogné sinon.
  static String? edit({required String? previous, required String typed}) {
    final text = typed.trim();
    final before = previous?.trim() ?? '';
    if (text == before) return null;
    return text;
  }

  /// Le commentaire à montrer : `null` si absent, ou vidé en attente d'envoi.
  static String? visible(String? stored) {
    final text = stored?.trim();
    return text == null || text.isEmpty ? null : text;
  }
}
