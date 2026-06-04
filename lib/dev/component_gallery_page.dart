import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/components/buttons/eteelo_fab.dart';
import 'package:school_app_flutter/core/components/buttons/primary_button.dart';
import 'package:school_app_flutter/core/components/buttons/secondary_button.dart';
import 'package:school_app_flutter/core/components/status/status_badge.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Page technique de validation visuelle de la Spec 2 (composants génériques).
///
/// Accessible via /dev/components en mode debug.
/// Ne pas intégrer dans les routes de production.
class ComponentGalleryPage extends StatefulWidget {
  const ComponentGalleryPage({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  bool _primaryLoading = false;
  bool _secondaryLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.componentGalleryTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            child: SyncIndicator(status: SyncStatus.synced),
          ),
          SizedBox(width: AppSpacing.sm),
        ],
      ),
      floatingActionButton: EteeloFab(
        label: 'Nouvelle inscription',
        icon: Icons.add,
        onPressed: () {},
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // ----------------------------------------------------------------
          // PrimaryButton
          // ----------------------------------------------------------------
          const _SectionHeader(title: 'PrimaryButton'),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            label: 'Valider l\'inscription',
            icon: Icons.check,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            label: 'Chargement…',
            onPressed: () => setState(() => _primaryLoading = !_primaryLoading),
            isLoading: _primaryLoading,
          ),
          const SizedBox(height: AppSpacing.sm),
          const PrimaryButton(label: 'Désactivé', onPressed: null),
          const SizedBox(height: AppSpacing.sm),
          PrimaryButton(
            label: 'Supprimer définitivement',
            icon: Icons.delete_forever,
            onPressed: () {},
            isDanger: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              PrimaryButton(
                label: 'compact',
                icon: Icons.add,
                onPressed: () {},
                fullWidth: false,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ----------------------------------------------------------------
          // SecondaryButton
          // ----------------------------------------------------------------
          const _SectionHeader(title: 'SecondaryButton'),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Annuler',
            icon: Icons.close,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpacing.sm),
          SecondaryButton(
            label: 'Chargement…',
            onPressed: () =>
                setState(() => _secondaryLoading = !_secondaryLoading),
            isLoading: _secondaryLoading,
          ),
          const SizedBox(height: AppSpacing.sm),
          const SecondaryButton(label: 'Désactivé', onPressed: null),
          const SizedBox(height: AppSpacing.xl),

          // ----------------------------------------------------------------
          // StudentAvatar
          // ----------------------------------------------------------------
          const _SectionHeader(title: 'StudentAvatar'),
          const SizedBox(height: AppSpacing.sm),
          const Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _AvatarLabel(
                avatar: StudentAvatar(
                  firstName: 'Jean',
                  lastName: 'Kabila',
                  studentId: 'demo-kabila',
                  size: AvatarSize.sm,
                ),
                label: 'sm (28) solid',
              ),
              _AvatarLabel(
                avatar: StudentAvatar(
                  firstName: 'Marie',
                  lastName: 'N\'Sumbu',
                  studentId: 'demo-nsumbu',
                  size: AvatarSize.md,
                ),
                label: 'md (32) — apostrophe',
              ),
              _AvatarLabel(
                avatar: StudentAvatar(
                  firstName: 'Pierre',
                  lastName: 'Ndombo-Kabongo',
                  studentId: 'demo-ndombo',
                  size: AvatarSize.lg,
                ),
                label: 'lg (48) — tiret',
              ),
              _AvatarLabel(
                avatar: StudentAvatar(
                  firstName: 'Élodie',
                  lastName: '',
                  studentId: 'demo-elodie',
                  size: AvatarSize.lg,
                ),
                label: 'lg (48) — lastName vide',
              ),
              _AvatarLabel(
                avatar: StudentAvatar(
                  firstName: 'Aline',
                  lastName: 'Bondo',
                  studentId: 'demo-bondo',
                  size: AvatarSize.xl,
                  variant: AvatarVariant.outlined,
                ),
                label: 'xl (64) outlined (pré-inscrit)',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ----------------------------------------------------------------
          // StatusBadge
          // ----------------------------------------------------------------
          const _SectionHeader(title: 'StatusBadge — Paiement'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusBadge.paid(label: 'Payé'),
              StatusBadge.partial(label: 'Partiel'),
              StatusBadge.overdue(label: 'En retard'),
              StatusBadge.cancelled(label: 'Annulé'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionHeader(title: 'StatusBadge — Présence'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusBadge.present(label: 'Présent'),
              StatusBadge.absentJustified(label: 'Justifié'),
              StatusBadge.absentUnjustified(label: 'Absent'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionHeader(title: 'StatusBadge — Synchro'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusBadge.synced(label: 'À jour'),
              StatusBadge.syncing(label: 'Synchro…'),
              StatusBadge.offline(label: 'Hors ligne'),
              StatusBadge.pendingUpload(label: 'À envoyer'),
              StatusBadge.syncConflict(label: 'Conflit'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionHeader(title: 'StatusBadge — Inscription'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusBadge.enrollmentPreRegistered(label: 'Pré-inscrit'),
              StatusBadge.enrollmentInProgress(label: 'En cours'),
              StatusBadge.enrollmentAdminCompleted(label: 'Complété (Admin)'),
              StatusBadge.enrollmentFinancialCompleted(
                label: 'Complété (Fin.)',
              ),
              StatusBadge.enrollmentCompleted(label: 'Complété'),
              StatusBadge.enrollmentCancelled(label: 'Annulé'),
              StatusBadge.enrollmentValidated(label: 'Validée'),
              StatusBadge.enrollmentRejected(label: 'Rejetée'),
              StatusBadge.enrollmentPending(label: 'En attente'),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _SectionHeader(title: 'StatusBadge — small'),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              StatusBadge.paid(label: 'Payé', size: StatusBadgeSize.small),
              StatusBadge.overdue(
                label: 'En retard',
                size: StatusBadgeSize.small,
              ),
              StatusBadge.offline(
                label: 'Hors ligne',
                size: StatusBadgeSize.small,
              ),
              StatusBadge.enrollmentInProgress(
                label: 'En cours',
                size: StatusBadgeSize.small,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ----------------------------------------------------------------
          // SyncIndicator — tous les états
          // ----------------------------------------------------------------
          const _SectionHeader(title: 'SyncIndicator — tous états'),
          const SizedBox(height: AppSpacing.sm),
          const Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              SyncIndicator(status: SyncStatus.synced),
              SyncIndicator(status: SyncStatus.syncing),
              SyncIndicator(status: SyncStatus.offline),
              SyncIndicator(status: SyncStatus.pendingUpload),
              SyncIndicator(status: SyncStatus.syncConflict),
            ],
          ),
          // Espace pour ne pas masquer le dernier élément avec le FAB
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary),
    );
  }
}

class _AvatarLabel extends StatelessWidget {
  final StudentAvatar avatar;
  final String label;

  const _AvatarLabel({required this.avatar, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        avatar,
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
