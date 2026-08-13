import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Porte d'entrée vers les écrans de développement (`kDebugMode` seul).
///
/// ## Pourquoi ce widget existe
///
/// `/dev/components` et `/dev/ticket-print` sont déclarées dans le routeur mais
/// n'étaient référencées **nulle part** : ni bouton, ni lien, ni menu. Elles
/// étaient donc inatteignables — la galerie de composants depuis sa création,
/// sans que personne ne le remarque, puisqu'on ne s'en sert pas pour travailler.
///
/// `flutter run --route=/dev/ticket-print` ne les rattrape pas : au démarrage
/// l'authentification est en `loading`, le redirect renvoie sur `/splash`, puis
/// sur `/home` une fois la session ouverte (`app_router.dart`). La route
/// initiale est mangée avant d'avoir servi.
///
/// L'enjeu n'est pas le confort : sans porte, le banc de calage thermique ne
/// peut pas servir, donc la page de code et l'avance papier — les deux seules
/// inconnues du lot L2.4 — ne peuvent pas se trancher.
///
/// ## Chaînes en dur, délibérément
///
/// Comme partout dans `lib/dev/` : un outil absent du build release n'a rien à
/// faire dans `app_fr.arb`/`app_en.arb`. C'est aussi ce qui garde la page
/// d'accueil — du code de production, elle — libre de toute chaîne non
/// localisée : elle n'appelle qu'un widget, et pas une seule étiquette.
///
/// ⚠️ Le garde `kDebugMode` est posé par l'**appelant**, pas ici : c'est ce qui
/// permet au compilateur d'éliminer la branche entière en release, comme le
/// routeur le fait déjà pour les deux `GoRoute` correspondantes.
class DevToolsEntry extends StatelessWidget {
  const DevToolsEntry({super.key});

  /// Libellé, icône, route — dans l'ordre d'utilité du moment.
  static const List<(String, IconData, String)> _tools = [
    (
      'Banc — impression thermique',
      Icons.print_outlined,
      AppRoutesNames.ticketPrintBench,
    ),
    (
      'Galerie de composants',
      Icons.widgets_outlined,
      AppRoutesNames.componentGallery,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xl),
      child: Column(
        children: [
          Text(
            'Outils de développement',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          // `TextButton` et pas `FilledButton`/`OutlinedButton` : ces deux-là
          // reçoivent du thème un `minimumSize` pleine largeur qui les ferait
          // s'empiler ici. Un outil de dev n'a de toute façon pas à peser plus
          // lourd à l'œil que la signature de marque qu'il suit.
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              for (final (label, icon, route) in _tools)
                TextButton.icon(
                  // `push` et non `go` : ces écrans sont des détours. Le retour
                  // système doit ramener à l'accueil, pas quitter l'application.
                  onPressed: () => context.push(route),
                  icon: Icon(icon),
                  label: Text(label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
