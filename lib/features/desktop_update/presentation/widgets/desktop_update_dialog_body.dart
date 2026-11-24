import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/desktop_release.dart';
import 'package:school_app_flutter/features/desktop_update/presentation/cubit/desktop_update_state.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Le contenu de la fenêtre selon l'étape.
class DesktopUpdateDialogBody extends StatelessWidget {
  final DesktopUpdateState state;

  const DesktopUpdateDialogBody({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final offer = state.offer!;
    return switch (state.status) {
      DesktopUpdateStatus.idle || DesktopUpdateStatus.available => _Proposal(
        offer: offer,
        mandatory: state.mandatory,
      ),
      DesktopUpdateStatus.preparing => _Progress(
        label: l10n.desktopUpdatePreparing,
        value: null,
      ),
      DesktopUpdateStatus.confirmPending => _Text(
        state.pendingOperations > 0
            ? l10n.desktopUpdatePendingBody(state.pendingOperations)
            : l10n.desktopUpdatePendingUnknown,
      ),
      DesktopUpdateStatus.downloading => _Progress(
        label: l10n.desktopUpdateDownloading((state.progress * 100).round()),
        value: state.progress,
      ),
      DesktopUpdateStatus.installing => _Progress(
        label: l10n.desktopUpdateInstalling,
        value: null,
      ),
      DesktopUpdateStatus.waitingForInstaller => _Progress(
        label: l10n.desktopUpdateWaitingInstaller,
        value: null,
      ),
      DesktopUpdateStatus.failed => _Text(switch (state.error) {
        DesktopUpdateError.network => l10n.desktopUpdateErrorNetwork,
        DesktopUpdateError.integrity => l10n.desktopUpdateErrorIntegrity,
        DesktopUpdateError.install => l10n.desktopUpdateErrorInstall,
        DesktopUpdateError.storage => l10n.desktopUpdateErrorStorage,
        DesktopUpdateError.unknown || null => l10n.desktopUpdateErrorUnknown,
      }),
    };
  }
}

class _Proposal extends StatelessWidget {
  final DesktopUpdateOffer offer;
  final bool mandatory;

  const _Proposal({required this.offer, required this.mandatory});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final english = Localizations.localeOf(context).languageCode == 'en';
    final release = offer.release;
    final sizeMb = (release.size / (1024 * 1024)).toStringAsFixed(0);
    // Les notes de chaque version manquée ; à défaut, celles de la version
    // proposée (signées avec elle).
    final notes = offer.notesSince.isNotEmpty
        ? offer.notesSince
        : [
            DesktopReleaseNotes(
              version: release.version,
              notesFr: release.notesFr,
              notesEn: release.notesEn,
            ),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (mandatory) ...[
          _Text(l10n.desktopUpdateMandatoryBody('${release.version}')),
          const SizedBox(height: AppSpacing.md),
        ],
        _Text(l10n.desktopUpdateAvailableBody(sizeMb)),
        const SizedBox(height: AppSpacing.lg),
        Text(l10n.desktopUpdateNotesTitle, style: AppTypography.titleSmall),
        for (final entry in notes) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.desktopUpdateNotesVersion('${entry.version}'),
            style: AppTypography.labelMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Builder(
            builder: (context) {
              final text =
                  (english && entry.notesEn.trim().isNotEmpty
                          ? entry.notesEn
                          : entry.notesFr)
                      .trim();
              return Text(
                text.isEmpty ? l10n.desktopUpdateNoNotes : text,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  final String label;

  /// `null` : progression indéterminée.
  final double? value;

  const _Progress({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      _Text(label),
      const SizedBox(height: AppSpacing.md),
      LinearProgressIndicator(value: value),
    ],
  );
}

class _Text extends StatelessWidget {
  final String text;

  const _Text(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppTypography.bodyMedium);
}
