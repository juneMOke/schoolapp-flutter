import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_band.dart';
import 'package:school_app_flutter/core/components/charts/eteelo_kpi_card_data.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_query.dart';
import 'package:school_app_flutter/features/staff/domain/services/staff_file_view.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La synthèse du fichier : l'effectif, les dossiers incomplets, et ce qui est
/// encore sur la tablette.
///
/// Les chiffres seulement : filtrer se fait par les puces de la carte de
/// filtres, qui portent déjà l'effectif de chaque contrat — deux commandes
/// pour le même filtre se contrediraient au premier tap.
class StaffStatsBand extends StatelessWidget {
  final StaffFileView view;

  const StaffStatsBand({super.key, required this.view});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final withoutContract = view.byContract[StaffContractFilter.none] ?? 0;
    return EteeloKpiBand(
      cards: [
        EteeloKpiCardData(
          label: l10n.staffStatHeadcount,
          value: view.all.length,
          accent: AppColors.bleuArdoise,
          accentSoft: AppColors.bleuArdoiseSoft,
          icon: Icons.groups_outlined,
          subline: withoutContract == 0
              ? null
              : l10n.staffStatHeadcountNoContract(withoutContract),
        ),
        if (view.documentsVisible)
          EteeloKpiCardData(
            label: l10n.staffStatIncomplete,
            value: view.incomplete,
            accent: AppColors.staffPartialInk,
            accentSoft: AppColors.feeStatusPartialSoft,
            icon: Icons.folder_off_outlined,
            subline: l10n.staffStatIncompleteSub,
          ),
        EteeloKpiCardData(
          label: l10n.staffStatPending,
          value: view.pending,
          accent: AppColors.staffPartialInk,
          accentSoft: AppColors.feeStatusPartialSoft,
          icon: Icons.cloud_off_outlined,
          subline: l10n.staffStatPendingSub,
        ),
      ],
    );
  }
}
