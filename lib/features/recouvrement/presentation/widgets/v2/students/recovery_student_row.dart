import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/components/controls/eteelo_activatable.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/dashboard_tones.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_overflow_text.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_students_page.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_student_row_parts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/v2/students/recovery_students_texts.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les trois dispositions d'une ligne d'élève (§4.6 E).
enum RecoveryStudentRowLayout {
  /// Élève · Classe · Payé · Reste · Situation · œil.
  wide,

  /// 600 à 760 reçus : la classe sous le nom, le payé sous le reste.
  compact,

  /// Sous 600 : nom et œil, puis statut et « Payé … · Reste … ».
  card,
}

/// Les parts de largeur des colonnes, partagées par l'en-tête et les lignes
/// (`RecStudentList`).
const recoveryWideFlex = [20, 10, 10, 10, 11];
const recoveryCompactFlex = [20, 11, 12];

/// Une ligne de la liste nominative (D9) : fond vert ou rouge pâle, liseré
/// gauche de 4 dp, et toujours le mot « En ordre » / « À relancer » (A18).
/// Toucher la ligne, l'œil ou Entrée ouvre la fiche (I11).
class RecoveryStudentRowTile extends StatelessWidget {
  final RecoveryStudentRow row;
  final RecoveryStudentRowLayout layout;
  final List<String> currencies;
  final bool first;
  final VoidCallback onTap;

  const RecoveryStudentRowTile({
    super.key,
    required this.row,
    required this.layout,
    required this.currencies,
    required this.first,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tone = row.inOrder
        ? DashboardSense.encaisse
        : DashboardSense.manquant;
    final className = row.classroomId == null
        ? l10n.recouvrementUnassigned
        : row.classroomName ?? l10n.recouvrementUnassigned;
    final idLine = row.matriculationNumber;
    final sub = switch (layout) {
      RecoveryStudentRowLayout.wide => [
        ?idLine,
        if (row.parentName?.trim().isNotEmpty ?? false) row.parentName!,
      ],
      _ => [?idLine, className],
    }.join(' · ');
    final outstandingTone = row.situation == StudentChargeStatus.paid
        ? DashboardSense.encaisse
        : DashboardSense.manquant;
    final identity = _Identity(row: row, subtitle: sub);
    final eye = RecoveryEye(
      label: l10n.recoveryStudentsViewSheet(row.displayName),
    );
    final situation = RecoverySituationBadges(row: row);

    final Widget content = switch (layout) {
      RecoveryStudentRowLayout.wide => Row(
        spacing: AppSpacing.sm + 2,
        children: [
          Expanded(flex: recoveryWideFlex[0], child: identity),
          Expanded(
            flex: recoveryWideFlex[1],
            child: EteeloOverflowText(
              className,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: recoveryWideFlex[2],
            child: RecoveryMoneyLines(
              amounts: row.paid,
              currencies: currencies,
            ),
          ),
          Expanded(
            flex: recoveryWideFlex[3],
            child: RecoveryMoneyLines(
              amounts: row.outstanding,
              currencies: currencies,
              tone: outstandingTone,
            ),
          ),
          Expanded(flex: recoveryWideFlex[4], child: situation),
          eye,
        ],
      ),
      RecoveryStudentRowLayout.compact => Row(
        spacing: AppSpacing.sm + 2,
        children: [
          Expanded(flex: recoveryCompactFlex[0], child: identity),
          Expanded(
            flex: recoveryCompactFlex[1],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                RecoveryMoneyLines(
                  amounts: row.outstanding,
                  currencies: currencies,
                  tone: outstandingTone,
                ),
                RecoveryPaidUnder(amounts: row.paid, currencies: currencies),
              ],
            ),
          ),
          Expanded(flex: recoveryCompactFlex[2], child: situation),
          eye,
        ],
      ),
      RecoveryStudentRowLayout.card => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xs,
        children: [
          Row(
            spacing: AppSpacing.sm + 2,
            children: [
              Expanded(child: identity),
              eye,
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AvatarSize.sm + AppSpacing.sm + 2,
            ),
            child: RecoveryCardAmounts(
              row: row,
              currencies: currencies,
              outstandingTone: outstandingTone,
            ),
          ),
        ],
      ),
    };

    return EteeloActivatable(
      semanticLabel: [
        row.displayName,
        className,
        row.inOrder
            ? l10n.recoveryStudentsInOrder
            : l10n.recoveryStudentsToChase,
      ].join(' · '),
      onActivate: onTap,
      builder: (context, highlight) => Container(
        constraints: const BoxConstraints(
          minHeight: AppDimensions.recoveryStudentsRowMinHeight,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: DashboardTones.teinte(
            tone,
            highlight.any
                ? RecoveryStudentsTones.hoverPercent
                : RecoveryStudentsTones.softPercent,
          ),
          border: Border(
            left: BorderSide(
              color: tone,
              width: AppDimensions.recoveryStudentsRowStripe,
            ),
            top: first
                ? BorderSide.none
                : const BorderSide(color: AppColors.border),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: content,
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final RecoveryStudentRow row;
  final String subtitle;

  const _Identity({required this.row, required this.subtitle});

  @override
  Widget build(BuildContext context) => Row(
    spacing: AppSpacing.sm + 2,
    children: [
      PersonAvatar(
        // « NOM Prénom » : le premier mot donne la première initiale.
        firstName: _rest(row.displayName),
        lastName: row.displayName.trim().split(' ').first,
        personId: row.studentId,
        size: AvatarSize.sm,
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            EteeloOverflowText(
              row.displayName,
              style: AppTypography.titleSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle.isNotEmpty)
              EteeloOverflowText(
                subtitle,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

String _rest(String name) {
  final words = name.trim().split(' ');
  return words.length > 1 ? words.sublist(1).join(' ') : '';
}
