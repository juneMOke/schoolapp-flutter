import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/branding/eteelo_logo.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/school/domain/entities/school_logo.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La marque à poser en tête d'une surface : le **sceau de l'établissement**
/// quand il en a un, le symbole ETEELO sinon.
///
/// ## Le repli n'est pas un cas d'erreur, c'est le cas ordinaire
///
/// Une école sans logo déposé, un référentiel pas encore pullé, une première
/// installation encore hors ligne : les trois donnent le même écran, celui
/// d'avant ce lot. Aucune surface n'a donc à traiter d'état vide — l'absence de
/// sceau est l'absence d'un ajout.
///
/// ## Ce que ce widget ne décide PAS : la vignette qui le porte
///
/// Les surfaces de marque de l'app sont **Bleu Profond**, et le symbole ETEELO
/// y est dessiné pour cela. Le sceau d'une école, lui, est inconnu : un logo à
/// traits foncés y disparaîtrait. Il lui faut un fond clair — mais la vignette
/// qui le porte appartient à l'appelant (le médaillon de l'Accueil a son halo,
/// la tête de barre latérale son carré, et les deux ont leur taille). Ce widget
/// rend donc la marque **seule**, et offre [plateColor] pour que chaque site
/// choisisse son fond sans réinventer la règle.
///
/// ```dart
/// final logo = SchoolBrandMark.logoOf(context);
/// DecoratedBox(
///   decoration: BoxDecoration(
///     color: SchoolBrandMark.plateColor(logo, idle: Colors.transparent),
///   ),
///   child: SchoolBrandMark(logo: logo, size: 36),
/// );
/// ```
class SchoolBrandMark extends StatelessWidget {
  /// Le sceau à servir, `null` pour le symbole ETEELO. Lu par [logoOf].
  ///
  /// Passé en argument plutôt que relu ici : l'appelant en a besoin de son côté
  /// pour décorer sa vignette, et deux lectures diraient la même chose deux
  /// fois.
  final SchoolLogo? logo;

  /// Côté de la marque en dp. Le sceau est carré (PNG 256×256) et le symbole
  /// ETEELO l'est aussi : la même valeur convient aux deux.
  final double size;

  /// Variante du symbole ETEELO servie en repli. Les surfaces de marque étant
  /// foncées, c'est la variante fond foncé par défaut.
  final EteeloLogoVariant fallbackVariant;

  const SchoolBrandMark({
    super.key,
    required this.logo,
    required this.size,
    this.fallbackVariant = EteeloLogoVariant.symbolOnDark,
  });

  /// Le sceau détenu pour l'école de la session, `null` s'il n'y en a pas.
  ///
  /// ⚠️ Lecture **défensive** : la plupart des surfaces de marque se montent
  /// aussi dans des tests de layout isolés, sans aucun bloc de session au-dessus
  /// — même précaution que la bannière d'accueil pour la session et l'année.
  static SchoolLogo? logoOf(BuildContext context) {
    try {
      return context.watch<SchoolIdentityCubit>().state.logo;
    } catch (_) {
      return null;
    }
  }

  /// Le fond de la vignette qui porte la marque.
  ///
  /// Opaque et clair dès qu'un sceau s'affiche : c'est la seule garantie qu'un
  /// logo aux traits foncés reste lisible sur le Bleu Profond. Sous le symbole
  /// ETEELO, la surface garde son fond habituel [idle] — une pastille pleine
  /// sous lui se lirait comme un cerne.
  static Color plateColor(SchoolLogo? logo, {required Color idle}) =>
      logo == null ? idle : AppColors.blancCasse;

  @override
  Widget build(BuildContext context) {
    final logo = this.logo;
    if (logo == null) {
      return EteeloLogo(variant: fallbackVariant, size: size);
    }

    return Image.memory(
      logo.bytes,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      // Le sceau change quand l'école en dépose un nouveau : garder l'ancien à
      // l'écran le temps du décodage évite un trou dans la vignette.
      gaplessPlayback: true,
      semanticLabel: AppLocalizations.of(context)!.schoolLogoSemanticsLabel,
      // Des octets vérifiés au tirage peuvent devenir indécodables — une base
      // abîmée, un format que le décodeur de la plateforme refuse. Le repli est
      // celui de tous les autres cas : la marque ETEELO, jamais un trou ni une
      // icône de rupture.
      errorBuilder: (context, _, _) =>
          EteeloLogo(variant: fallbackVariant, size: size),
    );
  }
}
