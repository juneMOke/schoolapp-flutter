import 'package:flutter/widgets.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';

/// Couleur d'accent + teinte douce assignées à une classe de façon
/// déterministe (par position dans la liste). Reprend la charte « Mes cours »
/// (4 teintes cycliques) à partir des tokens existants — zéro couleur en dur.
class AcademicsClassVisual {
  final Color accent;
  final Color soft;

  const AcademicsClassVisual({required this.accent, required this.soft});

  static const List<AcademicsClassVisual> _palette = [
    AcademicsClassVisual(
      accent: AppColors.bleuArdoise,
      soft: AppColors.bleuArdoiseSoft,
    ),
    AcademicsClassVisual(
      accent: AppColors.info,
      soft: AppColors.accueilDisciplinesSoft,
    ),
    AcademicsClassVisual(
      accent: AppColors.terreCuite,
      soft: AppColors.terreCuiteSoft,
    ),
    AcademicsClassVisual(
      accent: AppColors.vertSavane,
      soft: AppColors.accueilFinancesSoft,
    ),
  ];

  /// Teinte déterministe d'une classe selon sa position dans la liste.
  static AcademicsClassVisual forIndex(int index) =>
      _palette[index % _palette.length];
}

/// Décompose le nom d'une classe (ex. « 7e CTEB A ») en un niveau (première
/// partie) et une éventuelle section (dernière partie courte, ex. « A ») pour
/// le médaillon. Best-effort, purement présentation — ne lève jamais.
class ClassroomIdentity {
  final String level;
  final String? section;

  const ClassroomIdentity({required this.level, this.section});

  factory ClassroomIdentity.fromName(String name) {
    final tokens = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) {
      return const ClassroomIdentity(level: '—');
    }
    final level = tokens.first;
    String? section;
    if (tokens.length > 1) {
      final last = tokens.last;
      if (last.length <= 2 && last != level) {
        section = last.toUpperCase();
      }
    }
    return ClassroomIdentity(level: level, section: section);
  }
}
