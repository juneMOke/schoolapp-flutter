import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/resultats/presentation/helpers/resultats_labels.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En-tête de la vue focus (spec §6) : bandeau dégradé Bleu Profond → Bleu
/// Ardoise, bouton retour, avatar, identité, et deux statistiques (moyenne
/// annuelle en or doux, rang sur N classés). Rendu dès le chargement à partir de
/// l'identité passée en argument, enrichi par l'entête chargée.
class ResultatFocusHeader extends StatelessWidget {
  final String prenom;
  final String nom;
  final String? postnom;
  final ClassroomMemberGender? genre;
  final String classroomLabel;
  final String studentId;
  final double? moyenneAnnuelle;
  final int? rang;
  final int nbClasses;
  final VoidCallback onBack;

  const ResultatFocusHeader({
    super.key,
    required this.prenom,
    required this.nom,
    required this.postnom,
    required this.genre,
    required this.classroomLabel,
    required this.studentId,
    required this.moyenneAnnuelle,
    required this.rang,
    required this.nbClasses,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = [
      l10n.resultatsFocusClassroom(classroomLabel),
      resultatsGenderLabel(l10n, genre),
    ].where((p) => p.trim().isNotEmpty).join(' · ');

    return ClipRRect(
      borderRadius: AppRadius.brLg,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _BackButton(
                onTap: onBack,
                semanticsLabel: l10n.resultatsFocusBack,
              ),
              StudentAvatar(
                firstName: prenom,
                lastName: nom,
                studentId: studentId,
                size: AvatarSize.lg,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 160, maxWidth: 260),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      resultatsFullName(prenom, nom, postnom),
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textOnDark,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textOnDark.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
              _StatPill(
                value: resultatsPercent(l10n, moyenneAnnuelle),
                label: l10n.resultatsFocusAnnualAverage,
                valueColor: AppColors.orDoux,
              ),
              _StatPill(
                value: rang == null ? l10n.resultatsDash : '$rang',
                label: l10n.resultatsFocusRankOf(nbClasses),
                valueColor: AppColors.textOnDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;
  final String semanticsLabel;

  const _BackButton({required this.onTap, required this.semanticsLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.brMd,
          onTap: onTap,
          child: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.textOnDark.withValues(alpha: 0.08),
              borderRadius: AppRadius.brMd,
              border: Border.all(
                color: AppColors.textOnDark.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              size: 18,
              color: AppColors.textOnDark,
            ),
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  final Color valueColor;

  const _StatPill({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.textOnDark.withValues(alpha: 0.09),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.textOnDark.withValues(alpha: 0.14)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              fontFamily: 'Lora',
              color: valueColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textOnDark.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
