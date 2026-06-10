/// Contenu éditorial du panneau de marque ETEELO CONNECT des écrans d'auth.
///
/// Découple la structure du panneau ([AuthBrandPanel]) de son copy : la
/// connexion et le flux de réinitialisation partagent le même rendu mais
/// fournissent chacun leur propre titre/sous-texte (décision produit). Le mot
/// [highlight] doit être une sous-chaîne **exacte** de [title] et de
/// [condensedTitle] — il est mis en Or Doux par [AuthBrandPanel].
class AuthBrandContent {
  /// Titre éditorial Lora plein (variante split).
  final String title;

  /// Titre condensé (variante bandeau 560–900 dp).
  final String condensedTitle;

  /// Mot accentué en Or Doux — sous-chaîne exacte de [title]/[condensedTitle].
  final String highlight;

  /// Sous-texte Inter (variante split uniquement).
  final String subtitle;

  const AuthBrandContent({
    required this.title,
    required this.condensedTitle,
    required this.highlight,
    required this.subtitle,
  });
}
