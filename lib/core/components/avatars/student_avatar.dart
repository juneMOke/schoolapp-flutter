import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/helpers/avatar_palette.dart';
import 'package:school_app_flutter/core/helpers/initials_helper.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Tailles standard d'avatar (diamètre en dp), alignées sur l'usage réel.
/// Pour les cas particuliers déjà tokenisés (ex. attendance), passer la valeur
/// via `AppDimensions` plutôt qu'un nombre magique.
abstract final class AvatarSize {
  static const double sm = 28;
  static const double md = 32;
  static const double lg = 48;
  static const double xl = 64;
}

/// Variante visuelle de l'avatar élève.
///
/// La variante porte le **statut** ; la teinte de fond porte l'**identité** de
/// l'élève (deux axes orthogonaux).
enum AvatarVariant {
  /// Fond = teinte d'identité, initiales Blanc Cassé. Variante par défaut
  /// (élève inscrit, 95 % des cas).
  solid,

  /// Fond Papier, bordure et initiales = teinte d'identité.
  /// Réservé aux élèves en attente / pré-inscrits.
  outlined,
}

/// Avatar circulaire d'un élève affichant ses initiales.
///
/// - Ordre NOM-Prénom (convention RDC), initiales via [InitialsHelper].
/// - Teinte d'identité déterministe par élève via [AvatarPalette] (palette
///   tournante auditée WCAG AA, voir [AppColors]).
/// - Taille de police = [size] × 0.36 pour garantir la lisibilité.
/// - La teinte et les initiales ne portent aucune information : elles sont
///   exclues du lecteur d'écran sauf si [semanticLabel] est fourni (cas d'un
///   avatar isolé sans nom affiché à côté).
class StudentAvatar extends StatelessWidget {
  /// Ratio police / diamètre — lisible à toutes les échelles.
  static const double _initialsRatio = 0.36;

  final String firstName;
  final String lastName;

  /// Identifiant **stable** de l'élève (id), clé de la teinte d'identité.
  /// On utilise l'id et non le nom pour que la couleur ne change pas si le
  /// nom est corrigé.
  final String studentId;

  /// Diamètre en dp. Tailles standard : [AvatarSize.sm] / md / lg / xl.
  final double size;

  final AvatarVariant variant;

  /// Si fourni → annoncé tel quel par le lecteur d'écran (avatar isolé).
  /// Sinon, l'avatar est exclu de l'arbre sémantique (le nom est supposé
  /// affiché à côté → évite la redite).
  final String? semanticLabel;

  const StudentAvatar({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.studentId,
    this.size = AvatarSize.md,
    this.variant = AvatarVariant.solid,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final initials = InitialsHelper.initialsFrom(firstName, lastName);
    final tint = AvatarPalette.colorFor(studentId);
    final isSolid = variant == AvatarVariant.solid;

    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSolid ? tint : AppColors.surfaceAlt,
        border: isSolid ? null : Border.all(color: tint, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: AppTextStyles.avatarInitials.copyWith(
          fontSize: size * _initialsRatio,
          color: isSolid ? AppColors.blancCasse : tint,
        ),
      ),
    );

    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        excludeSemantics: true,
        child: avatar,
      );
    }
    return ExcludeSemantics(child: avatar);
  }
}
