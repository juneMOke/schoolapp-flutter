import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/widgets/content_max_width.dart';
import 'package:school_app_flutter/core/components/selection/desktop_selection_area.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/kuba_pattern_layer.dart';
import 'package:school_app_flutter/core/widgets/page_background_halos.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';

enum AppPageBackgroundStyle { decorated, flat }

/// Fond visuel standard partagé par toutes les pages de l'application
/// (gradient doux + orbes décoratifs + zone centrée scrollable).
class AppPageBackground extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final AppPageBackgroundStyle style;
  final Color flatBackgroundColor;

  /// Fiche en lecture : le texte se sélectionne et se copie sur bureau et
  /// navigateur (cf. [DesktopSelectionArea], qui dit pourquoi pas partout).
  final bool selectableText;

  /// Plafond du contenu : la largeur de lecture par défaut, ou
  /// [PageContentWidth.wide] pour une liste, un tableau, un tableau de bord.
  final PageContentWidth width;

  const AppPageBackground({
    super.key,
    required this.child,
    this.scrollable = true,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.style = AppPageBackgroundStyle.decorated,
    this.flatBackgroundColor = AppColors.surface,
    this.selectableText = false,
    this.width = PageContentWidth.reading,
  });

  double _horizontalPadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < AppBreakpoints.phoneNarrowMax) {
      return AppDimensions.spacingM;
    }
    return AppDimensions.spacingL;
  }

  /// Marge basse du contenu. Un FAB flottant n'est pas dans le flux : il se
  /// pose PAR-DESSUS les derniers dp de la page, à droite — là où le pied de
  /// tableau range sa pagination. On lui réserve sa place plutôt que de le
  /// laisser masquer ce qu'il recouvre.
  ///
  /// La marge système (barre gestuelle, encoche en paysage, barre d'état sans
  /// barre d'en-tête) s'y ajoute : Android 15 impose le bord à bord, et le
  /// fond, lui, doit continuer de couvrir tout l'écran. Un `Scaffold` qui a
  /// déjà posé une barre d'en-tête ou une barre basse a retiré la sienne.
  EdgeInsets _contentPadding(BuildContext context) {
    return EdgeInsets.fromLTRB(
          _horizontalPadding(context),
          AppDimensions.spacingL,
          _horizontalPadding(context),
          floatingActionButton == null
              ? AppDimensions.spacingL
              : AppDimensions.fabScrollClearance,
        ) +
        MediaQuery.paddingOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final content = ContentMaxWidth(
      maxWidth: width.maxWidthIn(context),
      child: selectableText ? DesktopSelectionArea(child: child) : child,
    );

    final body = style == AppPageBackgroundStyle.flat
        ? DecoratedBox(
            decoration: BoxDecoration(color: flatBackgroundColor),
            child: Builder(
              builder: (context) => _buildScrollableContent(context, content),
            ),
          )
        : DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.pageBackgroundGradientStart,
                  AppColors.pageBackgroundGradientEnd,
                ],
              ),
            ),
            child: Stack(
              children: [
                const PageBackgroundHalos(),
                const KubaPatternLayer(),
                Builder(
                  builder: (context) =>
                      _buildScrollableContent(context, content),
                ),
              ],
            ),
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: _aboveKeyboard(context, bottomNavigationBar),
      body: body,
    );
  }

  /// Une barre basse (total à encaisser, « Enregistrer ») reste au-dessus du
  /// clavier : le `Scaffold` la pose au bas de l'écran, où le clavier la
  /// couvre — l'agent tapait un montant sans voir le total. Le corps se
  /// rétrécit d'autant, rien n'est recouvert.
  static Widget? _aboveKeyboard(BuildContext context, Widget? bar) {
    if (bar == null) return null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: bar,
    );
  }

  /// Appelé SOUS le `Scaffold` de la page (`Builder`) : la marge système y est
  /// déjà amputée de ce que la barre d'en-tête ou la barre basse ont consommé.
  Widget _buildScrollableContent(BuildContext context, Widget content) {
    if (scrollable) {
      return SingleChildScrollView(
        padding: _contentPadding(context),
        child: content,
      );
    }

    return Padding(padding: _contentPadding(context), child: content);
  }
}
