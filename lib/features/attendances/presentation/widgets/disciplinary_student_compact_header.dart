import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/student_gender.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// En-tête d'identité compact de la fiche élève (coquille, V1).
///
/// À gauche : avatar + nom (post-nom prénom) + méta « classe · niveau · genre ».
/// À droite (ou dessous sur étroit) : un chip de synthèse « cas ouverts »
/// (rouge si > 0, vert « Aucun cas ouvert » sinon). [openCasesCount] null = le
/// compte n'est pas encore connu (chip masqué). Le chip « présence (année) »
/// est volontairement omis en V1 (donnée non disponible à la coquille).
class DisciplinaryStudentCompactHeader extends StatelessWidget {
  final String studentId;
  final String firstName;
  final String lastName;
  final String? middleName;

  /// Genre en valeur API (MALE / FEMALE / OTHER).
  final String gender;
  final String levelName;
  final String classroomName;
  final int? openCasesCount;

  const DisciplinaryStudentCompactHeader({
    super.key,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.gender,
    required this.levelName,
    required this.classroomName,
    this.openCasesCount,
  });

  /// En deçà, le chip de synthèse passe sous l'identité (spec §03).
  static const double _wrapBreakpoint = 520;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final chip = _openCasesChip(l10n);

    final identity = Row(
      children: [
        StudentAvatar(
          firstName: firstName,
          lastName: lastName,
          studentId: studentId,
          size: AppDimensions.spacingXL + AppDimensions.spacingM,
        ),
        const SizedBox(width: AppDimensions.spacingM),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _buildDisplayName(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle.copyWith(
                  fontFamily: 'Lora',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.bleuArdoise,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _buildMeta(l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (chip == null) return identity;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= _wrapBreakpoint) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppDimensions.spacingM),
              chip,
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            identity,
            const SizedBox(height: AppDimensions.spacingS),
            chip,
          ],
        );
      },
    );
  }

  String _buildDisplayName(AppLocalizations l10n) {
    final fullName = [
      lastName,
      middleName,
      firstName,
    ].where((p) => (p ?? '').trim().isNotEmpty).join(' ').trim();
    return fullName.isEmpty ? l10n.disciplinaryUnknownValue : fullName;
  }

  String _buildMeta(AppLocalizations l10n) {
    final parts = <String>[
      if (classroomName.trim().isNotEmpty) classroomName.trim(),
      if (levelName.trim().isNotEmpty) levelName.trim(),
      StudentGenderX.fromApiValue(gender).getDisplayName(l10n),
    ];
    return parts.join(' · ');
  }

  Widget? _openCasesChip(AppLocalizations l10n) {
    final count = openCasesCount;
    if (count == null) return null;
    final hasOpen = count > 0;
    return _SummaryChip(
      icon: hasOpen ? Icons.error_outline : Icons.check_circle_outline,
      label: hasOpen
          ? l10n.dossierOpenCasesChip(count)
          : l10n.dossierNoOpenCases,
      foreground: hasOpen ? AppColors.error : AppColors.vertSavane,
      background: hasOpen
          ? AppColors.presenceStateUnjustifiedSoft
          : AppColors.presenceStatePresentSoft,
    );
  }
}

/// Chip de synthèse arrondi (icône + libellé) — couleur portée par le texte ET
/// l'icône (jamais la couleur seule).
class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS + 2,
        vertical: AppDimensions.spacingXS,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: foreground),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            label,
            style: AppTextStyles.badge.copyWith(
              color: foreground,
              fontFeatures: AppTextStyles.tabularFigures,
            ),
          ),
        ],
      ),
    );
  }
}
