import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/web/browser_tab_title.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/core/components/app_bars/dark_bar_parts.dart';
import 'package:school_app_flutter/core/components/app_bars/student_detail_avatar_badge.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

export 'package:school_app_flutter/core/components/app_bars/student_detail_app_bar_pill.dart';

/// AppBar sombre des dossiers élève — Inscription, Facturation, Discipline,
/// Documents.
///
/// Reprend la TopBar applicative — Bleu Profond texturé Kuba — et la
/// contextualise à un élève : retour, avatar à initiales, sur-titre or-doux,
/// nom complet, pastille de synthèse optionnelle à droite. Un liseré or-doux
/// la sépare du contenu.
///
/// Chaque module fournit sa propre pastille [trailing] : la synthèse affichée
/// (solde, cas ouverts…) est du métier, la barre n'en connaît que la place.
class StudentDetailAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  static const double _backSize = 42;
  static const double _avatarSize = 42;
  static const double _closeSize = 40;
  static const double _dividerHeight = 2;

  /// Part de la largeur que la pastille de synthèse peut prendre.
  static const double _trailingMaxShare = 0.4;

  final String fullName;
  final String eyebrow;
  final String firstName;
  final String lastName;

  /// Route rejointe quand la pile de navigation est vide (lien profond).
  final String fallbackRoute;

  /// Pastille de synthèse affichée à droite (cf. [StudentDetailAppBarPill]).
  final Widget? trailing;

  /// Croix de fermeture à l'extrême droite, en plus du retour.
  ///
  /// Réservée aux dossiers dont on « sort » (Facturation) ; ailleurs, la
  /// flèche de retour est la seule sortie. Jamais sur un téléphone : elle y
  /// doublerait la flèche au prix du nom.
  final bool showCloseButton;

  /// Remplace la sortie par défaut (retour, sinon [fallbackRoute]).
  ///
  /// Un écran de SAISIE ne se quitte pas d'un tap : la page d'encaissement
  /// branche ici sa confirmation de perte de saisie, la même que celle du
  /// retour système. Sans ce crochet, la flèche `pop`ait directement — un
  /// `PopScope` ne voit pas passer un `Navigator.pop` explicite.
  final VoidCallback? onExit;

  /// L'élève du dossier : sa photo remplace les initiales quand il en a une.
  final String? studentId;

  const StudentDetailAppBar({
    super.key,
    required this.fullName,
    required this.eyebrow,
    required this.firstName,
    required this.lastName,
    required this.fallbackRoute,
    this.trailing,
    this.showCloseButton = false,
    this.onExit,
    this.studentId,
  });

  @override
  Size get preferredSize =>
      const Size.fromHeight(AppDimensions.topBarHeight + _dividerHeight);

  void _onExit(BuildContext context) {
    final custom = onExit;
    if (custom != null) {
      custom();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(fallbackRoute);
  }

  String get _initials {
    final letters = [lastName, firstName]
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .take(2)
        .map((value) => value.characters.first.toUpperCase())
        .join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // L'onglet du navigateur nomme l'élève tant que sa fiche est ouverte.
    return BrowserTabTitle(
      title: l10n.browserTabTitle(fullName),
      fallback: l10n.schoolApp,
      child: LayoutBuilder(
        // La largeur reçue, pas celle de l'écran : posée dans un volet à côté
        // de sa liste (`EmbeddedRecordPane`), la barre n'a que celle du volet.
        builder: (context, constraints) => _bar(context, constraints.maxWidth),
      ),
    );
  }

  Widget _bar(BuildContext context, double width) {
    // Téléphone : la flèche suffit pour sortir, et le nom passe avant la
    // photo — à 360 dp, retour + avatar + pastille + croix ne laissaient
    // plus de place au nom de l'élève.
    final showClose =
        showCloseButton && width >= AppBreakpoints.detailCompactMax;
    final showAvatar = width >= AppBreakpoints.phoneNarrowMax;
    final trailing = this.trailing;
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: AppColors.textOnDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: AppDimensions.topBarHeight,
      titleSpacing: AppDimensions.spacingS,
      leadingWidth: AppDimensions.spacingM + _backSize + AppDimensions.spacingS,
      flexibleSpace: const KubaTopBarBackground(),
      leading: Padding(
        padding: const EdgeInsets.only(left: AppDimensions.spacingM),
        child: Align(
          alignment: Alignment.centerLeft,
          child: DarkBarIconButton(
            size: _backSize,
            baseColor: _white(0.10),
            hoverColor: _white(0.08),
            icon: Icons.arrow_back_rounded,
            iconSize: 22,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            onTap: () => _onExit(context),
          ),
        ),
      ),
      title: Row(
        children: [
          if (showAvatar) ...[
            StudentDetailAvatarBadge(
              initials: _initials,
              size: _avatarSize,
              studentId: studentId,
            ),
            const SizedBox(width: AppDimensions.spacingM),
          ],
          Expanded(
            child: DarkBarHeading(eyebrow: eyebrow, title: fullName),
          ),
        ],
      ),
      actions: [
        if (trailing != null)
          Padding(
            padding: EdgeInsets.only(
              right: showClose
                  ? AppDimensions.spacingS
                  : AppDimensions.spacingM,
            ),
            // La synthèse s'abrège plutôt que d'effacer le nom.
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: width * _trailingMaxShare,
                ),
                child: trailing,
              ),
            ),
          ),
        if (showClose)
          Padding(
            padding: const EdgeInsets.only(right: AppDimensions.spacingM),
            child: DarkBarIconButton(
              size: _closeSize,
              baseColor: _white(0.06),
              hoverColor: _white(0.08),
              icon: Icons.close_rounded,
              iconSize: 20,
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onTap: () => _onExit(context),
            ),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_dividerHeight),
        child: GoldDivider(height: _dividerHeight, colors: _dividerColors),
      ),
    );
  }

  /// Liseré or-doux en halo centré (opacité .55).
  static final List<Color> _dividerColors = [
    AppColors.orDoux.withValues(alpha: 0),
    AppColors.orDoux.withValues(alpha: 0.55),
    AppColors.orDoux.withValues(alpha: 0),
  ];

  static Color _white(double opacity) =>
      AppColors.textOnDark.withValues(alpha: opacity);
}
