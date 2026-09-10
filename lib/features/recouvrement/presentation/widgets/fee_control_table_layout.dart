import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart'
    as core_avatar;
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/money/money_bag.dart';
import 'package:school_app_flutter/core/money/money_format.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/fee_status_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Colonnes et lignes du tableau, dans ses deux dispositions.
///
/// ## L'ordre n'est pas réordonnable
///
/// Les colonnes ne portent plus de tri : la liste sort **du moins avancé au
/// plus avancé**, et cet ordre EST la priorité de relance. Laisser trier par
/// nom rendrait la feuille d'appel dépendante d'un clic, et deux impressions du
/// même périmètre pourraient différer.
///
/// ## Six colonnes en large, trois en étroit
///
/// Sous ~1024 dp, Dû et Payé passent en ligne secondaire sous Reste plutôt que
/// d'être tronqués par l'ellipse — un montant tronqué est un chiffre faux.
class FeeControlTableLayout {
  const FeeControlTableLayout._();

  static List<DataTableColumnDef> columns(
    AppLocalizations l10n, {
    required bool wide,
  }) {
    if (!wide) {
      return [
        // Sans libellé : l'action « Sélectionner la page » vit dans l'en-tête
        // de section, pas dans la colonne.
        const DataTableColumnDef(label: '', flex: 1),
        DataTableColumnDef(label: l10n.feeControlColumnStudent, flex: 4),
        DataTableColumnDef(
          label: l10n.facturationDetailChargeRemainingAmountColumn,
          flex: 3,
        ),
        DataTableColumnDef(
          label: l10n.facturationDetailChargeStatusColumn,
          flex: 3,
        ),
      ];
    }

    return [
      const DataTableColumnDef(label: '', flex: 1),
      DataTableColumnDef(label: l10n.feeControlColumnStudent, flex: 4),
      // Les colonnes de montant pèsent autant que les noms.
      DataTableColumnDef(
        label: l10n.facturationDetailChargeExpectedAmountColumn,
        flex: 3,
      ),
      DataTableColumnDef(
        label: l10n.facturationDetailChargePaidAmountColumn,
        flex: 3,
      ),
      DataTableColumnDef(
        label: l10n.facturationDetailChargeRemainingAmountColumn,
        flex: 3,
      ),
      DataTableColumnDef(
        label: l10n.facturationDetailChargeStatusColumn,
        flex: 3,
      ),
    ];
  }

  static List<DataTableRowSpec> rows(
    List<FeeControlRow> rows,
    AppLocalizations l10n, {
    required bool wide,
    required ExchangeRate? rate,
    required Set<String> selected,
    required Set<String> marked,
    required ValueChanged<FeeControlRow> onViewRequested,
    required ValueChanged<FeeControlRow> onRowTapped,
    required ValueChanged<FeeControlRow> onSelectionToggled,
  }) {
    return rows
        .map((row) {
          final student = row.summary.student;
          final expected = money(row.expected);
          final paid = money(row.paid);
          final remaining = money(row.remaining);

          // Teintes sur un PRÉDICAT, pas sur un montant : « quelque chose a
          // été payé », « il reste quelque chose » — dans n'importe quelle
          // devise.
          final paidColor = _paidColor(!row.paid.isAllZero);
          final remainingColor = _remainingColor(!row.remaining.isAllZero);

          final name = DataTableCellSpec(
            text: '${student.lastName} ${student.firstName}',
            variant: DataTableCellTextVariant.strong,
            // ⚠️ La spec écrit ici « matricule · payeur ». Le payeur n'a pas de
            // source locale pour un élève déjà inscrit (`guardian_phone` ne vit
            // que sur les tables de candidats), et l'inventer serait pire que
            // l'omettre. Reste le code du dossier, que l'école lit déjà.
            secondaryText: row.summary.enrollmentCode.isEmpty
                ? null
                : row.summary.enrollmentCode,
          );

          return DataTableRowSpec(
            // L'identité de ligne est l'ÉLÈVE : un candidat sans dossier porte
            // un `enrollmentId` vide, qui ferait collisionner plusieurs lignes.
            id: student.id,
            displayName: '${student.lastName} ${student.firstName}',
            leading: core_avatar.StudentAvatar(
              firstName: student.firstName,
              lastName: student.lastName,
              studentId: student.id,
              size: core_avatar.AvatarSize.sm,
            ),
            onTap: () => onRowTapped(row),
            cells: wide
                ? [
                    _selectCell(row, selected, marked, onSelectionToggled),
                    name,
                    // L'attendu reste neutre : c'est la référence, pas un verdict.
                    _amount(expected),
                    _amount(paid, color: paidColor),
                    _amount(remaining, color: remainingColor),
                    _situation(row, l10n, rate),
                  ]
                : [
                    _selectCell(row, selected, marked, onSelectionToggled),
                    name,
                    DataTableCellSpec(
                      text: remaining,
                      variant: DataTableCellTextVariant.mono,
                      color: remainingColor,
                      secondaryText: '$paid / $expected',
                      secondaryVariant: DataTableCellTextVariant.mono,
                      secondaryColor: paidColor,
                    ),
                    _situation(row, l10n, rate),
                  ],
            trailing: DataTableTrailingSpec(
              type: DataTableTrailingType.eye,
              tooltip: l10n.feeControlViewDetailLabel,
              onTap: () => onViewRequested(row),
            ),
          );
        })
        .toList(growable: false);
  }

  /// La case à cocher, et le rappel qu'un élève est déjà sur la liste des
  /// renvois.
  ///
  /// Une **cellule** et non le `leading` de la ligne : celui-ci est borné à
  /// 36 dp par le tableau partagé, où une case et un avatar ne tiennent pas.
  static DataTableCellSpec _selectCell(
    FeeControlRow row,
    Set<String> selected,
    Set<String> marked,
    ValueChanged<FeeControlRow> onSelectionToggled,
  ) => DataTableCellSpec(
    child: _SelectCell(
      checked: selected.contains(row.studentId),
      marked: marked.contains(row.studentId),
      onToggled: () => onSelectionToggled(row),
    ),
  );

  /// La pastille classe, le taux nuance.
  static DataTableCellSpec _situation(
    FeeControlRow row,
    AppLocalizations l10n,
    ExchangeRate? rate,
  ) {
    final percent = row.hasNoExpectation ? null : row.ratePercent(rate);
    return DataTableCellSpec(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: FeeStatusBadge(
              label: row.status.localizedLabel(l10n),
              visuals: row.status.visuals,
            ),
          ),
          const SizedBox(width: AppDimensions.spacingXS),
          Text(
            // Un tiret plutôt qu'un « 0 % » : rien n'était attendu, ou aucun
            // cours ne rapproche les deux devises de la ligne. Les deux se
            // disent « on ne sait pas », pas « rien n'a été payé ».
            percent == null ? '—' : '$percent %',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  static DataTableCellSpec _amount(String text, {Color? color}) =>
      DataTableCellSpec(
        text: text,
        variant: DataTableCellTextVariant.mono,
        textAlign: TextAlign.end,
        color: color,
      );

  /// Encaissé : la teinte « payé » dès qu'il y a de l'argent, gris sinon — un
  /// zéro en vert se lirait comme une bonne nouvelle.
  static Color _paidColor(bool anythingPaid) => anythingPaid
      ? StudentChargeStatus.paid.badgeColor
      : AppColors.textSecondary;

  /// Reste : la teinte « à régler » tant qu'il en reste, « payé » à zéro. Ce
  /// sont les mêmes teintes que la pastille de statut de la même ligne.
  static Color _remainingColor(bool anythingDue) => anythingDue
      ? StudentChargeStatus.due.badgeColor
      : StudentChargeStatus.paid.badgeColor;

  /// Un sac rendu sur une seule ligne de cellule. Vide → tiret : « aucune
  /// créance » n'est pas « zéro dollar ».
  static String money(MoneyBag bag) =>
      bag.isEmpty ? '—' : bag.entries.map(MoneyFormat.format).join(' · ');
}

/// La case, et le rappel qu'un élève est déjà sur la liste des renvois.
class _SelectCell extends StatelessWidget {
  final bool checked;
  final bool marked;
  final VoidCallback onToggled;

  const _SelectCell({
    required this.checked,
    required this.marked,
    required this.onToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ⚠️ Le tap de la case ne doit PAS ouvrir la fiche : cocher n'est pas
        // consulter. `Checkbox` absorbe le geste, la ligne ne le voit pas.
        Checkbox(
          value: checked,
          onChanged: (_) => onToggled(),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        if (marked) ...[
          const SizedBox(width: AppDimensions.spacingXS),
          const _MarkedDot(),
        ],
      ],
    );
  }
}

/// Le rappel « à renvoyer », visible sans ouvrir la fiche.
class _MarkedDot extends StatelessWidget {
  const _MarkedDot();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: l10n.feeControlMarkedBadge,
      child: const Icon(
        Icons.person_off_outlined,
        size: AppDimensions.recouvrementFeeChipIconSize,
        color: AppColors.error,
      ),
    );
  }
}
