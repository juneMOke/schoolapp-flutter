import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/components/search/search_mode_switch.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/features/boutique/presentation/bloc/beneficiary_picker_cubit.dart';
import 'package:school_app_flutter/features/boutique/presentation/widgets/boutique_cart_line_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// « Désigner un élève » — les deux voies de la spec §09.
///
/// **Bascule exclusive** (règle non négociable #12) : recherche libre quand on
/// connaît le nom, repli par niveau quand on ne l'a pas. Jamais deux blocs
/// concurrents reliés par un « OU ».
///
/// Fermer la modale sans choisir n'est **pas une erreur** : la ligne reste sans
/// bénéficiaire, et le niveau reste une issue.
class BoutiqueBeneficiaryDialog extends StatefulWidget {
  final List<BoutiqueLevelOption> levels;

  const BoutiqueBeneficiaryDialog({super.key, required this.levels});

  /// Ouvre la modale et rend l'élève choisi, ou `null` si l'on ferme.
  ///
  /// Le cubit est fourni par l'appelant : c'est lui qui connaît l'année, et
  /// c'est aussi lui qui le referme (`FeatureScope` du dépôt).
  static Future<BeneficiaryCandidate?> show(
    BuildContext context, {
    required BeneficiaryPickerCubit cubit,
    required List<BoutiqueLevelOption> levels,
  }) => showDialog<BeneficiaryCandidate>(
    context: context,
    builder: (_) => BlocProvider<BeneficiaryPickerCubit>.value(
      value: cubit,
      child: BoutiqueBeneficiaryDialog(levels: levels),
    ),
  );

  @override
  State<BoutiqueBeneficiaryDialog> createState() =>
      _BoutiqueBeneficiaryDialogState();
}

class _BoutiqueBeneficiaryDialogState extends State<BoutiqueBeneficiaryDialog> {
  /// ⚠️ Une clé par mode : sans elle, basculer réutilise le même `TextField` et
  /// **tue le `FocusNode`** — le clavier se referme et la saisie suivante part
  /// dans le vide. Piège déjà payé sur les modales à bascule de ce dépôt.
  final GlobalKey _searchFieldKey = GlobalKey();
  final TextEditingController _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);

    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: size.height * 0.82,
        ),
        child: EteeloDialogBody(
          // Seul l'en-tête reste ancré : en paysage clavier ouvert, figer aussi
          // les critères écraserait la liste sur une tablette 10".
          minPinnedHeight: 160,
          header: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EteeloDialogDarkHeader(
                eyebrow: l10n.boutiqueBeneficiaryEyebrow,
                title: l10n.boutiqueBeneficiaryTitle,
                onClose: () => Navigator.of(context).pop(),
              ),
              const EteeloDialogGoldDivider(),
            ],
          ),
          bodyPadding: const EdgeInsets.all(AppDimensions.spacingL),
          footer: const [],
          body: BlocBuilder<BeneficiaryPickerCubit, BeneficiaryPickerState>(
            builder: (context, state) {
              final cubit = context.read<BeneficiaryPickerCubit>();

              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SearchModeSwitch(
                    selected: state.mode,
                    enabled: state.status != BeneficiaryPickerStatus.loading,
                    onChanged: cubit.switchMode,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  if (state.mode == SearchMode.identity)
                    TextField(
                      key: _searchFieldKey,
                      controller: _queryController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText: l10n.boutiqueBeneficiarySearchLabel,
                        hintText: l10n.boutiqueBeneficiarySearchPlaceholder,
                        prefixIcon: const Icon(Icons.search, size: 18),
                      ),
                      onChanged: cubit.queryChanged,
                    )
                  else
                    EteeloSelectInput<String>(
                      // Le champ n'avait aucun intitulé : une liste de
                      // niveaux ouverte sans rien dire de ce qu'elle sert à
                      // filtrer. Le mode « par identité », lui, nomme son
                      // champ.
                      label: l10n.schoolLevelLabel,
                      value: state.schoolLevelId,
                      enabled: state.status != BeneficiaryPickerStatus.loading,
                      minWidth: 0,
                      items: [
                        for (final level in widget.levels)
                          EteeloSelectItem<String>(
                            value: level.id,
                            label: level.label,
                          ),
                      ],
                      onChanged: cubit.levelChanged,
                    ),
                  const SizedBox(height: AppDimensions.spacingM),
                  _PriceHint(text: l10n.boutiqueBeneficiaryHint),
                  const SizedBox(height: AppDimensions.spacingM),
                  _Results(state: state),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// L'aide qui dit **pourquoi** on désigne un élève : ce n'est pas une formalité,
/// c'est ce qui résout le prix sans qu'on saisisse un montant (invariant I-2).
class _PriceHint extends StatelessWidget {
  final String text;

  const _PriceHint({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppDimensions.spacingS),
    decoration: BoxDecoration(
      color: AppColors.vertSavane.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 15, color: AppColors.vertSavane),
        const SizedBox(width: AppDimensions.spacingS),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    ),
  );
}

class _Results extends StatelessWidget {
  final BeneficiaryPickerState state;

  const _Results({required this.state});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (state.status == BeneficiaryPickerStatus.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingL),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.status == BeneficiaryPickerStatus.failure) {
      return _Note(text: l10n.boutiqueBeneficiaryLoadFailed);
    }

    // Sous le seuil : une INVITE, pas un vide — et elle nomme l'autre mode,
    // qui est la porte de sortie de qui cherche mal.
    if (state.mode == SearchMode.identity && state.queryTooShort) {
      return _Note(text: l10n.boutiqueBeneficiaryTooShort);
    }

    if (state.mode == SearchMode.level && state.schoolLevelId == null) {
      return _Note(text: l10n.boutiqueBeneficiaryPickLevel);
    }

    if (state.results.isEmpty) {
      return _Note(
        icon: Icons.search_off,
        // Le message CITE la requête : « aucun résultat » tout court laisse
        // chercher si l'on a mal tapé ou si l'élève n'existe pas.
        text: state.mode == SearchMode.identity
            ? l10n.boutiqueBeneficiaryNoResult(state.query)
            : l10n.boutiqueBeneficiaryLevelEmpty,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final candidate in state.results)
          _CandidateTile(candidate: candidate),
      ],
    );
  }
}

class _CandidateTile extends StatelessWidget {
  final BeneficiaryCandidate candidate;

  const _CandidateTile({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Un candidat non sélectionnable reste VISIBLE : le masquer enverrait le
    // guichet chercher un élève qu'il voit dans son registre. Ce qu'on lui doit,
    // c'est la raison et le repli — pas le silence.
    final blockedReason = candidate.enrollmentSynced
        ? (candidate.schoolLevelId == null
              ? l10n.boutiqueBeneficiaryNoLevel
              : null)
        : l10n.boutiqueBeneficiaryNotSynced;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      // ≥ 48 dp : on vise vite au guichet.
      minVerticalPadding: 8,
      enabled: candidate.isSelectable,
      leading: CircleAvatar(
        radius: 17,
        backgroundColor: AppColors.bleuArdoise.withValues(alpha: 0.12),
        child: Text(
          _initialsOf(candidate.fullName),
          style: const TextStyle(fontSize: 12, color: AppColors.bleuArdoise),
        ),
      ),
      title: Text(
        candidate.fullName,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        blockedReason ?? (candidate.schoolLevelName ?? ''),
        style: theme.textTheme.bodySmall?.copyWith(
          color: blockedReason == null
              ? AppColors.textMuted
              : AppColors.boutiqueUnresolvedText,
        ),
      ),
      trailing: candidate.isSelectable
          ? const Icon(Icons.chevron_right, size: 18)
          : null,
      onTap: candidate.isSelectable
          ? () => Navigator.of(context).pop(candidate)
          : null,
    );
  }

  static String _initialsOf(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _Note extends StatelessWidget {
  final String text;
  final IconData? icon;

  const _Note({required this.text, this.icon});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppDimensions.spacingM),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 26, color: AppColors.textMuted),
          const SizedBox(height: AppDimensions.spacingS),
        ],
        Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    ),
  );
}
