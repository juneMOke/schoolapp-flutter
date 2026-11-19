import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// La teinte d'un domaine de cours.
@immutable
class CourseDomainTone {
  final Color ink;
  final Color soft;

  /// [ink] assombrie au besoin : le fond d'un bandeau, texte clair dessus.
  final Color strong;

  const CourseDomainTone(this.ink, this.soft, {Color? strong})
    : strong = strong ?? ink;

  /// Une ligne sur deux : à peine teintée, les cases blanches s'en détachent.
  Color get wash => soft.withValues(alpha: 0.5);

  /// Le trait qui ouvre une ligne ou une séance : un fond, nommé comme tel.
  Color get mark => ink.withValues(alpha: 0.55);
}

/// Grammaire chromatique des **domaines de cours** (EDT-D10, Q12).
///
/// Avant ce fichier, la couleur d'un domaine n'existait que dans la palette de
/// Saisie des notes. L'emploi du temps colore ses séances par domaine : les
/// deux écrans doivent donner la même couleur au même domaine, donc la même
/// rotation, lue ici.
///
/// La rotation suit l'**ordre des domaines** de la grille de la classe (les
/// rubriques du bulletin) : le premier domaine prend [palette][0], et ainsi de
/// suite. Un domaine inconnu prend [unknown].
class CourseDomainTones {
  const CourseDomainTones._();

  static const List<CourseDomainTone> palette = [
    CourseDomainTone(AppColors.bleuArdoise, AppColors.bleuArdoiseSoft),
    CourseDomainTone(
      AppColors.terreCuite,
      AppColors.coteDomainTerreSoft,
      strong: AppColors.terreCuiteDark,
    ),
    CourseDomainTone(AppColors.vertSavane, AppColors.coteDomainVertSoft),
    CourseDomainTone(AppColors.coteDomainPrune, AppColors.coteDomainPruneSoft),
  ];

  /// Domaine absent ou hors de la grille (EDT-D10).
  static const unknown = CourseDomainTone(
    AppColors.textMuted,
    AppColors.calendarSchoolLifeSoft,
  );

  static CourseDomainTone forIndex(int? index) =>
      index == null || index < 0 ? unknown : palette[index % palette.length];

  /// La teinte de [domainCode] dans [orderedDomainCodes] (l'ordre de la
  /// grille), [unknown] s'il n'y figure pas.
  static CourseDomainTone forDomain(
    String? domainCode,
    List<String> orderedDomainCodes,
  ) => domainCode == null
      ? unknown
      : forIndex(orderedDomainCodes.indexOf(domainCode));
}
