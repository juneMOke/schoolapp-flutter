import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce que la barre de pied a à dire.
enum ConfigurationSaveBarMode {
  /// Un enregistrement est en vol.
  saving,

  /// Un enregistrement vient d'aboutir — jusqu'à la modification suivante.
  saved,

  /// Rien de particulier : c'est le hint de l'étape qui parle, ou le message
  /// par défaut.
  idle,
}

/// Barre d'enregistrement en pied d'étape.
///
/// **Le seul lieu de feedback de progression de l'assistant.** Ordre imposé :
/// Retour (fantôme, masqué à la première étape) · message extensible ·
/// Enregistrer (secondaire) · Continuer (primaire).
///
/// Les deux boutons se désactivent ensemble dès que l'étape n'est pas
/// franchissable : invalide, en chargement, en erreur, ou avec un sous-formulaire
/// ouvert. Laisser « Enregistrer » actif sur une étape en erreur inviterait à
/// figer un état que le serveur vient de refuser.
class ConfigurationSaveBar extends StatelessWidget {
  final ConfigurationSaveBarMode mode;

  /// Ce que l'étape veut dire quand elle bloque — « À compléter : Commune,
  /// E-mail », « Cochez au moins un niveau ». `null` : message par défaut.
  final String? hint;

  /// Libellé de la coche : « Enregistré » à l'étape 1, qui écrit vraiment,
  /// « Brouillon enregistré » aux étapes 2 à 4.
  final String savedLabel;

  final bool canSave;
  final bool canContinue;
  final bool showBack;

  final VoidCallback? onBack;
  final VoidCallback? onSave;
  final VoidCallback? onContinue;

  const ConfigurationSaveBar({
    super.key,
    required this.mode,
    required this.savedLabel,
    this.hint,
    this.canSave = false,
    this.canContinue = false,
    this.showBack = true,
    this.onBack,
    this.onSave,
    this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceRaised,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (showBack)
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: Text(l10n.configurationBack),
            ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _Message(mode: mode, hint: hint, saved: savedLabel),
          ),
          const SizedBox(width: AppSpacing.sm),
          // `minimumSize` explicite, obligatoire : le thème pose une largeur
          // `double.infinity` sur ces deux boutons — juste pour un bouton seul
          // en pleine largeur dans une colonne, fatal pour un bouton inline
          // dans un `Row`, où la contrainte infinie fait échouer la mise en
          // page. Convention du projet, déjà oubliée une fois.
          OutlinedButton(
            onPressed: canSave ? onSave : null,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppDimensions.minTouchTarget),
            ),
            child: Text(l10n.configurationSave),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton.icon(
            onPressed: canContinue ? onContinue : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, AppDimensions.minTouchTarget),
            ),
            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
            iconAlignment: IconAlignment.end,
            label: Text(l10n.configurationContinue),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final ConfigurationSaveBarMode mode;
  final String? hint;
  final String saved;

  const _Message({required this.mode, required this.hint, required this.saved});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return switch (mode) {
      ConfigurationSaveBarMode.saving => Text(
        l10n.configurationSaving,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      ),
      ConfigurationSaveBarMode.saved => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.vertSavane,
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              saved,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.vertSavane,
              ),
            ),
          ),
        ],
      ),
      // Le hint de l'étape s'il en fournit un, sinon le message par défaut.
      // L'étape « Année » n'en fournit pas : elle n'a que deux dates, et les
      // nommer n'ajouterait rien à ce que le champ montre déjà.
      ConfigurationSaveBarMode.idle => Text(
        hint ?? l10n.configurationSaveBarDefaultHint,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      ),
    };
  }
}
