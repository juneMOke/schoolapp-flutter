import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/guardian_empty_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/parent_item.dart';
import 'package:school_app_flutter/features/student/domain/entities/parent_summary.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';

class GuardianInfoStepBody extends StatelessWidget {
  final List<ParentSummary> parentDetails;
  final ParentItemStateChanged onItemStateChanged;
  final ParentItemValueChanged onItemValueChanged;
  final VoidCallback? onAddParent;

  /// Rattacher une fiche existante À LA PLACE du tuteur désigné — l'appel part
  /// du bandeau posé dans la carte elle-même ([GuardianLinkExistingBanner]),
  /// plus d'une loupe d'en-tête qui n'aurait désigné personne.
  final ValueChanged<String>? onLinkExistingParent;
  final ValueChanged<String>? onRemoveParent;
  final ValueChanged<String>? onOpenParent;
  final ValueChanged<String>? onPrimaryParentChanged;
  final String? expandedParentId;
  final String? primaryParentId;

  /// Tuteur désigné contact d'urgence, ou `null` si aucun. **Un seul id pour
  /// toutes les cartes** : l'exclusivité vient de la forme de cet état, pas
  /// d'une garde qu'on pourrait oublier d'écrire.
  final String? emergencyContactParentId;
  final ValueChanged<String?>? onEmergencyContactChanged;
  final bool isLoading;
  final bool canSave;
  final bool showInlineSaveButton;
  final VoidCallback onSave;
  final bool isEditable;

  /// Ids des tuteurs rattachés via "Rechercher un parent" cette session —
  /// leurs champs d'identité s'affichent en lecture seule (voir [ParentItem]).
  final Set<String> identityLockedParentIds;

  const GuardianInfoStepBody({
    super.key,
    required this.parentDetails,
    required this.onItemStateChanged,
    required this.onItemValueChanged,
    this.onAddParent,
    this.onLinkExistingParent,
    this.onRemoveParent,
    this.onOpenParent,
    this.onPrimaryParentChanged,
    this.expandedParentId,
    this.primaryParentId,
    this.emergencyContactParentId,
    this.onEmergencyContactChanged,
    this.isLoading = false,
    this.canSave = false,
    this.showInlineSaveButton = true,
    required this.onSave,
    this.isEditable = true,
    this.identityLockedParentIds = const <String>{},
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canAddParent = isEditable && !isLoading;

    return AbsorbPointer(
      absorbing: isLoading,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.brMd,
                border: Border.all(color: AppColors.border),
              ),
              child: _buildHeader(context, l10n, canAddParent),
            ),
            AnimatedSwitcher(
              duration: AppMotion.medium,
              switchInCurve: AppMotion.outCurve,
              switchOutCurve: AppMotion.inCurve,
              child: isLoading
                  ? Padding(
                      key: const ValueKey<String>('guardian-loading-bar'),
                      padding: const EdgeInsets.only(top: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: const LinearProgressIndicator(minHeight: 4),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 16),
            if (parentDetails.isEmpty)
              const GuardianEmptyState()
            else
              ...parentDetails.asMap().entries.map((entry) {
                final index = entry.key;
                final parent = entry.value;
                return Padding(
                  key: ValueKey<String>('parent-item-${parent.id}'),
                  padding: EdgeInsets.only(
                    bottom: index < parentDetails.length - 1 ? 16 : 0,
                  ),
                  child: ParentItem(
                    parent: parent,
                    isPrimary: primaryParentId == parent.id,
                    isExpanded: expandedParentId == parent.id,
                    onToggleExpanded: () => onOpenParent?.call(parent.id),
                    onPrimaryChanged: (checked) {
                      if (checked == true) {
                        onPrimaryParentChanged?.call(parent.id);
                      }
                    },
                    isEmergencyContact: emergencyContactParentId == parent.id,
                    // Décocher retire la désignation sans en poser d'autre :
                    // « aucun contact d'urgence » doit rester exprimable.
                    onEmergencyContactChanged: (checked) =>
                        onEmergencyContactChanged?.call(
                          checked == true ? parent.id : null,
                        ),
                    onFormStateChanged: onItemStateChanged,
                    onValueChanged: onItemValueChanged,
                    // Corbeille masquée s'il ne reste qu'un seul tuteur.
                    onRemoveRequested: isEditable && parentDetails.length > 1
                        ? () => onRemoveParent?.call(parent.id)
                        : null,
                    onLinkExistingRequested:
                        isEditable && !isLoading && onLinkExistingParent != null
                        ? () => onLinkExistingParent!.call(parent.id)
                        : null,
                    isEditable: isEditable,
                    identityLocked: identityLockedParentIds.contains(parent.id),
                  ),
                );
              }),
            if (showInlineSaveButton)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SessionWriteGate(
                  child: FilledButton.icon(
                    onPressed: canSave && !isLoading ? onSave : null,
                    icon: isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnDark,
                            ),
                          )
                        : const Icon(Icons.save_outlined, size: 18),
                    label: Text(l10n.guardianSaveAction),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      backgroundColor: AppColors.terreCuite,
                      foregroundColor: AppColors.textOnDark,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.brMd,
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    bool canAddParent,
  ) {
    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.guardianInformation,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.guardianPrimaryRequiredHint,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final stack =
            constraints.maxWidth < AppBreakpoints.guardianHeaderRowMin;
        // « Ajouter » est désormais la SEULE action de l'en-tête : le
        // rattachement d'une fiche connue a rejoint la carte qu'il remplace
        // (voir [GuardianLinkExistingBanner]).
        final addButton = SecondaryButton(
          onPressed: canAddParent ? onAddParent : null,
          icon: Icons.person_add_alt_1_rounded,
          label: l10n.guardianAddAction,
          // Empilé (téléphone) : bouton pleine largeur ; en ligne : intrinsèque.
          fullWidth: stack,
        );

        if (stack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              titleBlock,
              const SizedBox(height: AppSpacing.md),
              addButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleBlock),
            const SizedBox(width: AppSpacing.md),
            addButton,
          ],
        );
      },
    );
  }
}
