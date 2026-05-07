import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/helpers/initials_helper.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Variante visuelle de l'avatar élève.
enum AvatarVariant {
  /// Fond Bleu Ardoise, initiales Blanc Cassé. Variante par défaut (95 % des cas).
  solid,

  /// Fond Papier, bordure et initiales Bleu Ardoise.
  /// Réservé aux élèves en attente / pré-inscrits.
  outlined,
}

/// Avatar circulaire d'un élève affichant ses initiales.
///
/// - Ordre NOM-Prénom (convention RDC).
/// - Taille de police = [size] × 0.36 pour garantir la lisibilité à toutes les échelles.
/// - Délègue le calcul des initiales à [InitialsHelper].
class StudentAvatar extends StatelessWidget {
  final String firstName;
  final String lastName;

  /// Diamètre en dp. Tailles standards : 32 / 40 (défaut) / 48 / 64.
  final double size;

  final AvatarVariant variant;

  const StudentAvatar({
    super.key,
    required this.firstName,
    required this.lastName,
    this.size = 40,
    this.variant = AvatarVariant.solid,
  });

  @override
  Widget build(BuildContext context) {
    final initials = InitialsHelper.initialsFrom(firstName, lastName);
    final fontSize = size * 0.36;
    final isSolid = variant == AvatarVariant.solid;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSolid ? AppColors.bleuArdoise : AppColors.surfaceAlt,
        border: isSolid
            ? null
            : Border.all(color: AppColors.bleuArdoise, width: 1),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: isSolid ? AppColors.blancCasse : AppColors.bleuArdoise,
          height: 1,
        ),
      ),
    );
  }
}
