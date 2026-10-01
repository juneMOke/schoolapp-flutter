import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/person_avatar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/features/staff/domain/entities/staff_enums.dart';
import 'package:school_app_flutter/features/staff/presentation/bloc/staff_agent_state.dart';
import 'package:school_app_flutter/features/staff/presentation/helpers/staff_contract_tone.dart';
import 'package:school_app_flutter/core/components/status/record_sync_pill.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le bandeau de tête de la page agent : retour, avatar dans l'anneau de son
/// contrat, surtitre selon le mode, nom, et — en consultation — où en est la
/// fiche et l'accès à sa modification.
class StaffAgentHeader extends StatelessWidget {
  final StaffAgentState state;

  /// Le contrat en vigueur, pour l'anneau ; `null` = à poser.
  final StaffContractKind? kind;
  final VoidCallback onBack;

  /// Bouton « Modifier le profil » — `null` quand le compte ne peut pas
  /// écrire, ou hors consultation.
  final VoidCallback? onEdit;

  const StaffAgentHeader({
    super.key,
    required this.state,
    required this.kind,
    required this.onBack,
    this.onEdit,
  });

  static const double _avatarSize = 56;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = state.draft;
    final name = [
      draft.firstName,
      draft.lastName,
    ].where((part) => part.trim().isNotEmpty).join(' ');
    final eyebrow = switch (state.mode) {
      StaffAgentMode.create => l10n.staffAgentStepEyebrow(
        state.step + 1,
        StaffAgentState.stepCount,
      ),
      StaffAgentMode.edit => l10n.staffAgentEditEyebrow,
      StaffAgentMode.view => state.member?.jobTitle ?? '',
    };
    final member = state.member;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.bleuProfond,
            AppColors.bleuArdoise,
            AppColors.bleuArdoiseLight,
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              tooltip: l10n.staffActionBack,
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: AppColors.textOnDark),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: StaffContractTone.of(kind).soft,
                  width: 3,
                ),
              ),
              child: PersonAvatar(
                firstName: draft.firstName,
                lastName: draft.lastName,
                personId: draft.id,
                size: _avatarSize,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (eyebrow.isNotEmpty)
                    Text(
                      eyebrow.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.listeInkSubtitle,
                        letterSpacing: 0.6,
                      ),
                    ),
                  Text(
                    name.isEmpty ? l10n.staffAgentNew : name,
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textOnDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (state.mode == StaffAgentMode.view && member != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: AppRadius.brPill,
                ),
                child: RecordSyncPill(state: member.syncState),
              ),
            if (onEdit != null) ...[
              const SizedBox(width: AppSpacing.sm),
              EteeloButton.primary(
                label: l10n.staffActionEdit,
                icon: Icons.edit_outlined,
                onPressed: onEdit,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
