import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Couleur d'accent d'un cycle, et son fond doux.
class CycleAccent {
  final Color color;
  final Color surface;

  const CycleAccent(this.color, this.surface);
}

/// **La seule chose du référentiel pédagogique qui reste écrite dans
/// l'application.**
///
/// Tout le reste — codes, libellés, ordre, pré-cochage, barèmes, nombre de
/// cours — est servi par le catalogue. Une couleur, elle, n'a pas d'équivalent
/// côté serveur, et un cycle qu'on ne connaîtrait pas reçoit simplement
/// l'accent par défaut : il s'affiche, il ne disparaît pas.
///
/// Indexé sur le **code servi**, jamais sur un rang : le jour où le catalogue
/// gagne un cycle, les couleurs ne se décalent pas.
const Map<String, CycleAccent> _accents = {
  'MAT': CycleAccent(Color(0xFF9D174D), Color(0xFFFBEAF1)),
  'PRIM': CycleAccent(AppColors.vertSavane, Color(0xFFEDF5EF)),
  'CTEB': CycleAccent(Color(0xFF2E6E8E), Color(0xFFEAF2F7)),
  'HG': CycleAccent(Color(0xFFA9772E), Color(0xFFFBF4E4)),
};

const CycleAccent _fallback = CycleAccent(
  AppColors.bleuArdoise,
  AppColors.bleuArdoiseSoft,
);

CycleAccent cycleAccentOf(String cycleCode) => _accents[cycleCode] ?? _fallback;
