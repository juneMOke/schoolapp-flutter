import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// En-tête du panneau formulaire des écrans d'auth (charte §ANATOMIE 4) :
/// eyebrow (catégorie), titre éditorial Lora (h1 sémantique), sous-texte.
///
/// [stepper] est un emplacement optionnel inséré **entre le titre et le
/// sous-texte** : null pour la connexion, fourni pour le flux de
/// réinitialisation (indicateur de progression + libellé d'étape).
class AuthFormHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? stepper;

  const AuthFormHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.stepper,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.3,
            color: AppColors.terreCuite,
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1.1,
              color: AppColors.bleuProfond,
            ),
          ),
        ),
        if (stepper != null) ...[const SizedBox(height: 16), stepper!],
        SizedBox(height: stepper == null ? 6 : 14),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            height: 1.45,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
