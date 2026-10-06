import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_bloc.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/bloc_visual.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un bloc rendu en lecture (spec §8) : titre à trait terre cuite, paragraphe
/// aéré, liste à puces, encadré « À retenir », exemple.
class BlocLecture extends StatelessWidget {
  final ChapitreBloc bloc;
  final bool first;

  const BlocLecture({super.key, required this.bloc, this.first = false});

  static const double _titleTopMargin = 26;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return switch (bloc.type) {
      ChapitreBlocType.titre => Padding(
        padding: EdgeInsets.only(top: first ? 0 : _titleTopMargin),
        child: Semantics(
          header: true,
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: const BoxDecoration(
                  color: AppColors.terreCuite,
                  borderRadius: AppRadius.brPill,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  bloc.texte,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ChapitreBlocType.paragraphe => Text(
        bloc.texte,
        style: AppTypography.bodyLarge.copyWith(
          color: AppColors.textPrimary,
          height: 1.65,
        ),
      ),
      ChapitreBlocType.liste => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in bloc.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 9, right: AppSpacing.md),
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.bleuArdoise,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.bodyLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      ChapitreBlocType.encadre => _Aside(
        label: BlocVisual.short(l10n, bloc.type).toUpperCase(),
        icon: BlocVisual.icon(bloc.type),
        texte: bloc.texte,
        surface: AppColors.programmeEncadreSurface,
        accent: AppColors.programmeEncadreAccent,
      ),
      ChapitreBlocType.exemple => _Aside(
        label: BlocVisual.short(l10n, bloc.type),
        icon: BlocVisual.icon(bloc.type),
        texte: bloc.texte,
        surface: AppColors.surfaceAlt,
        accent: AppColors.bleuArdoise,
      ),
    };
  }
}

/// Un encadré à liséré gauche : « À retenir », « Exemple ».
class _Aside extends StatelessWidget {
  final String label;
  final IconData icon;
  final String texte;
  final Color surface;
  final Color accent;

  const _Aside({
    required this.label,
    required this.icon,
    required this.texte,
    required this.surface,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: surface,
      border: Border(left: BorderSide(color: accent, width: 4)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          texte,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
      ],
    ),
  );
}
