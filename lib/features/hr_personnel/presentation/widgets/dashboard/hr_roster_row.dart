import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/components/avatars/person_sync_avatar.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/core/components/tables/data_table_models.dart';
import 'package:school_app_flutter/core/offline/record_sync_state.dart';
import 'package:school_app_flutter/features/hr_personnel/domain/hr_staff_member_row.dart';
import 'package:school_app_flutter/features/hr_personnel/presentation/helpers/hr_personnel_labels.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_contract_badge.dart';
import 'package:school_app_flutter/features/staff/presentation/widgets/common/staff_dossier_meter.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Un agent en ligne de table : Agent · Catégorie · Contrat · Ancienneté, et
/// Dossier pour qui voit les pièces. L'avatar porte la pastille de la fiche
/// sur cette tablette ; toute la ligne ouvre la fiche, l'œil le redit.
abstract final class HrRosterRow {
  /// [sync] `null` tant que le fichier local n'est pas lu (ou illisible) : on
  /// ne sait pas où en est la fiche, et aucune pastille ne le prétend.
  ///
  /// [withDossier] : la colonne existe — vide pour une ligne sans compte, afin
  /// que les cellules restent sous leurs en-têtes.
  static DataTableRowSpec of(
    HrStaffMemberRow row,
    AppLocalizations l10n, {
    required RecordSyncState? sync,
    required bool withDossier,
    required VoidCallback onOpen,
  }) {
    final since = HrPersonnelLabels.monthYear(row.entryDate);
    final dossier = row.dossier;
    return DataTableRowSpec(
      id: row.id,
      displayName: row.fullName,
      leading: _avatar(row, l10n, sync),
      onTap: onOpen,
      trailing: DataTableTrailingSpec(
        type: DataTableTrailingType.eye,
        tooltip: l10n.hrRosterOpen,
        onTap: onOpen,
      ),
      cells: [
        DataTableCellSpec(
          text: row.fullName,
          variant: DataTableCellTextVariant.strong,
          secondaryText: row.jobTitle,
        ),
        DataTableCellSpec(
          text: HrPersonnelLabels.category(l10n, row.category),
          color: HrPersonnelLabels.categoryInk(row.category),
        ),
        DataTableCellSpec(
          text: '',
          child: StaffContractBadge(kind: row.contractKind),
        ),
        DataTableCellSpec(
          text: HrPersonnelLabels.seniorityOf(l10n, row.seniorityYears),
          variant: DataTableCellTextVariant.strong,
          secondaryText: since == null ? null : l10n.hrRosterSince(since),
        ),
        if (withDossier)
          dossier != null && dossier.required > 0
              ? DataTableCellSpec(
                  text: '',
                  child: Tooltip(
                    message: l10n.hrRosterDossierTooltip(
                      dossier.provided,
                      dossier.required,
                    ),
                    child: StaffDossierMeter.counts(
                      done: dossier.provided,
                      total: dossier.required,
                    ),
                  ),
                )
              : const DataTableCellSpec(),
      ],
    );
  }

  static Widget _avatar(
    HrStaffMemberRow row,
    AppLocalizations l10n,
    RecordSyncState? sync,
  ) {
    if (sync == null) {
      return PersonAvatar(
        firstName: row.firstName ?? '',
        lastName: row.lastName,
        personId: row.id,
        size: AvatarSize.md,
      );
    }
    // La pastille ne se lit qu'à la couleur : l'assistance vocale l'entend.
    return Semantics(
      label: RecordSyncPill.label(l10n, sync),
      child: PersonSyncAvatar(
        firstName: row.firstName ?? '',
        lastName: row.lastName,
        personId: row.id,
        sync: sync,
        size: AvatarSize.md,
      ),
    );
  }
}
