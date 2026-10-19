import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  /// Plafond de l'agrandissement du texte demandé par le système. Au-delà de
  /// ×1,3, les hauteurs plancher (cartes KPI, bandeaux, catalogue) rognent le
  /// texte sur un téléphone ; en deçà, le réglage de l'utilisateur est servi
  /// tel quel.
  static const double maxTextScaleFactor = 1.3;

  static const displayLarge = TextStyle(
    fontFamily: 'Lora',
    fontSize: 40,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const displayMedium = TextStyle(
    fontFamily: 'Lora',
    fontSize: 32,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const headlineLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  static const headlineMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 22,
    fontWeight: FontWeight.w600,
  );

  static const titleLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static const titleMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const titleSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const bodyLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const bodyMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const bodySmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  static const labelLarge = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const labelMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const labelSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  static const money = TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // Formulaires — Lora pour chaleur éditoriale
  static const labelFormLarge = TextStyle(
    fontFamily: 'Lora',
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static const labelFormMedium = TextStyle(
    fontFamily: 'Lora',
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static const formValueMedium = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const formValueSmall = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  // Numéro de pastille du stepper — chiffres tabulaires (largeur stable).
  static const stepNumber = TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
