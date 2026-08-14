import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart'
    as core_avatar;
import 'package:school_app_flutter/core/components/tables/index.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/widgets/currency_field.dart';
import 'package:school_app_flutter/features/finance/domain/entities/student_charge.dart';
import 'package:school_app_flutter/features/finance/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/finance/presentation/extensions/student_charge_status_ui_extension.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/common/fee_status_badge.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Colonnes triables du Contrôle des frais. `remaining` et `status` viennent des
/// montants agrégés, pas de l'élève — d'où un enum propre à cette table.
///
/// Les valeurs servent d'index de tri **stables** : elles ne changent pas avec
/// la disposition, si bien qu'un tri choisi en large survit au passage en
/// étroit.
enum FeeControlSortColumn { lastName, surname, firstName, remaining, status }

/// Colonnes et lignes du tableau, dans ses deux dispositions.
///
/// Sept colonnes ne tiennent pas sous ~1024 dp : en étroit, on garde identité,
/// reste et statut, et Attendu/Payé passent en ligne secondaire plutôt que
/// d'être tronqués par l'ellipse — un montant tronqué est un chiffre faux.
class FeeControlTableLayout {
  const FeeControlTableLayout._();

  static List<DataTableColumnDef> columns(
    AppLocalizations l10n, {
    required bool wide,
  }) {
    if (!wide) {
      return [
        DataTableColumnDef(
          label: l10n.lastName,
          flex: 4,
          sortable: true,
          sortIndex: FeeControlSortColumn.lastName.index,
        ),
        DataTableColumnDef(
          label: l10n.facturationDetailChargeRemainingAmountColumn,
          flex: 3,
          sortable: true,
          sortIndex: FeeControlSortColumn.remaining.index,
        ),
        DataTableColumnDef(
          label: l10n.facturationDetailChargeStatusColumn,
          flex: 3,
          sortable: true,
          sortIndex: FeeControlSortColumn.status.index,
        ),
      ];
    }

    return [
      DataTableColumnDef(
        label: l10n.lastName,
        flex: 3,
        sortable: true,
        sortIndex: FeeControlSortColumn.lastName.index,
      ),
      DataTableColumnDef(
        label: l10n.surname,
        flex: 2,
        sortable: true,
        sortIndex: FeeControlSortColumn.surname.index,
      ),
      DataTableColumnDef(
        label: l10n.firstName,
        flex: 2,
        sortable: true,
        sortIndex: FeeControlSortColumn.firstName.index,
      ),
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
        sortable: true,
        sortIndex: FeeControlSortColumn.remaining.index,
      ),
      DataTableColumnDef(
        label: l10n.facturationDetailChargeStatusColumn,
        flex: 3,
        sortable: true,
        sortIndex: FeeControlSortColumn.status.index,
      ),
    ];
  }

  static List<DataTableRowSpec> rows(
    List<FeeControlRow> rows,
    AppLocalizations l10n, {
    required bool wide,
    required ValueChanged<FeeControlRow> onViewRequested,
  }) {
    return rows.map((row) {
      final student = row.summary.student;
      final aggregate = row.aggregate;
      final expected = money(aggregate.expectedInCents, aggregate.currency);
      final paid = money(aggregate.paidTotalInCents, aggregate.currency);
      final remaining = money(aggregate.remainingInCents, aggregate.currency);
      final statusCell = DataTableCellSpec(
        child: FeeStatusBadge(
          label: row.status.localizedLabel(l10n),
          visuals: row.status.visuals,
        ),
      );

      final paidColor = _paidColor(aggregate.paidTotalInCents);
      final remainingColor = _remainingColor(aggregate.remainingInCents);

      return DataTableRowSpec(
        // L'identité de ligne est l'ÉLÈVE : un candidat sans dossier porte un
        // `enrollmentId` vide, qui ferait collisionner plusieurs lignes.
        id: student.id,
        displayName: '${student.lastName} ${student.firstName}',
        leading: core_avatar.StudentAvatar(
          firstName: student.firstName,
          lastName: student.lastName,
          studentId: student.id,
          size: core_avatar.AvatarSize.sm,
        ),
        cells: wide
            ? [
                DataTableCellSpec(
                  text: student.lastName,
                  variant: DataTableCellTextVariant.strong,
                ),
                DataTableCellSpec(text: student.surname),
                DataTableCellSpec(text: student.firstName),
                // L'attendu reste neutre : c'est la référence, pas un verdict.
                _amount(expected),
                _amount(paid, color: paidColor),
                _amount(remaining, color: remainingColor),
                statusCell,
              ]
            : [
                DataTableCellSpec(
                  text: '${student.lastName} ${student.firstName}',
                  variant: DataTableCellTextVariant.strong,
                  secondaryText: student.surname,
                ),
                DataTableCellSpec(
                  text: remaining,
                  variant: DataTableCellTextVariant.mono,
                  color: remainingColor,
                  secondaryText: '$paid / $expected',
                  secondaryVariant: DataTableCellTextVariant.mono,
                  secondaryColor: paidColor,
                ),
                statusCell,
              ],
        trailing: DataTableTrailingSpec(
          type: DataTableTrailingType.eye,
          tooltip: l10n.feeControlViewDetailLabel,
          onTap: () => onViewRequested(row),
        ),
      );
    }).toList(growable: false);
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
  static Color _paidColor(int paidInCents) => paidInCents > 0
      ? StudentChargeStatus.paid.badgeColor
      : AppColors.textSecondary;

  /// Reste : la teinte « à régler » tant qu'il en reste, « payé » à zéro. Ce
  /// sont les mêmes teintes que la pastille de statut de la même ligne.
  static Color _remainingColor(int remainingInCents) => remainingInCents > 0
      ? StudentChargeStatus.due.badgeColor
      : StudentChargeStatus.paid.badgeColor;

  static String money(int cents, String currency) =>
      formatMonetaryAmountWithCurrency(
        amount: cents / 100,
        currency: currency,
      );
}
