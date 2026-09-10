import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/money/exchange_rate.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fiche/fee_control_fee_line.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **L'aperçu d'un élève : frais par frais, chacun dans sa devise.**
///
/// Le tableau agrège les frais retenus ; la fiche les désagrège. C'est ici
/// qu'on comprend qu'un élève « partiel » a soldé son inscription et rien versé
/// sur la scolarité.
///
/// ## Ce qu'elle montre, et ce qu'elle ne montre pas
///
/// ⚠️ La spec veut « toujours les quatre frais, pas seulement les frais
/// retenus : la fiche est la vérité complète du dossier ». Elle montre ici les
/// frais **retenus** — ceux qui sont déjà en mémoire. Aller chercher le reste
/// demanderait une seconde lecture du registre pour un seul élève, et le
/// registre se lit école entière. La vérité complète du dossier existe déjà
/// ailleurs, dans la fiche financière de la Facturation, et le pied y mène :
/// l'aperçu **lit**, la fiche **agit**.
class FeeControlStudentSheet extends StatelessWidget {
  final FeeControlRow row;

  /// Grille du niveau, pour nommer chaque frais comme l'école l'a écrit.
  final List<LocalFeeTariff> tariffs;

  /// Cours du jour — le taux d'une ligne mixte en dépend, jamais un montant
  /// affiché.
  final ExchangeRate? rate;

  /// Vrai quand l'élève est déjà sur la liste de travail des renvois : le
  /// bouton bascule alors dans l'autre sens.
  final bool marked;

  final VoidCallback onToggleMark;

  /// Ouvre la fiche financière complète. Ferme d'abord l'aperçu : deux écrans
  /// du même élève empilés n'apprennent rien de plus.
  final VoidCallback onOpenRecord;

  const FeeControlStudentSheet({
    super.key,
    required this.row,
    required this.tariffs,
    required this.rate,
    required this.marked,
    required this.onToggleMark,
    required this.onOpenRecord,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final student = row.summary.student;
    final mixed = row.currencies.length > 1;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppDimensions.recouvrementStudentSheetMaxWidth,
          maxHeight: AppDimensions.recouvrementCallListMaxHeight,
        ),
        child: EteeloDialogBody(
          minPinnedHeight: AppDimensions.recouvrementStudentSheetMinPinned,
          bodyPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
          ),
          header: _Header(
            row: row,
            name: '${student.lastName} ${student.firstName}',
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.spacingS),
              for (final charge in row.line.charges)
                FeeControlFeeLine(charge: charge, tariffs: tariffs, rate: rate),
              if (mixed) ...[
                const SizedBox(height: AppDimensions.spacingS),
                Text(
                  l10n.feeControlSheetMixedNote,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
              const SizedBox(height: AppDimensions.spacingS),
            ],
          ),
          footer: [
            EteeloButton.ghost(
              label: l10n.feeControlSheetOpenRecord,
              icon: Icons.open_in_new,
              onPressed: onOpenRecord,
              fullWidth: false,
              size: EteeloButtonSize.compact,
            ),
            const SizedBox(width: AppDimensions.spacingS),
            EteeloButton.primary(
              label: marked
                  ? l10n.feeControlSheetUnmark
                  : l10n.feeControlMarkAction,
              icon: Icons.person_off_outlined,
              onPressed: onToggleMark,
              fullWidth: false,
              size: EteeloButtonSize.compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final FeeControlRow row;
  final String name;

  const _Header({required this.row, required this.name});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = row.summary;
    // Le niveau vient de la LIGNE quand elle le porte : une recherche par
    // identité n'en transporte aucun, et les critères mentiraient sur un élève
    // trouvé ailleurs.
    final eyebrow = [
      ?summary.schoolLevelName,
      ?summary.schoolLevelGroupName,
    ].join(' · ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow.isNotEmpty)
            Text(
              eyebrow.toUpperCase(),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
          Text(name, style: AppTextStyles.sectionTitle),
          if (summary.enrollmentCode.isNotEmpty)
            Text(
              l10n.feeControlSheetDossier(summary.enrollmentCode),
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
