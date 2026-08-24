import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/components/skeletons/eteelo_list_skeleton.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_empty_result.dart';
import 'package:school_app_flutter/core/widgets/eteelo_error_result.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/entities/local_parent.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_bloc.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_event.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/parent_search_state.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/guardian_info/parent_search_results_list.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Popin de sortie du conflit d'unicité téléphone de l'étape Tuteurs.
///
/// La garde locale refuse deux tuteurs portant le même numéro. Elle ne se
/// contentait que d'un toast — vrai, mais sans issue : l'utilisateur y
/// apprenait que la fiche existe sans pouvoir s'en servir, et le seul geste
/// qui lui restait était de rouvrir la recherche et de retaper le numéro qu'il
/// venait de saisir. La popin fait donc le pas suivant : elle remonte la ou
/// les fiches qui portent ce numéro et propose de rattacher directement celle
/// qui convient — la fiche choisie **remplace** le tuteur en cours de saisie.
///
/// Renvoie la fiche retenue, ou `null` si l'utilisateur préfère corriger le
/// numéro (rien n'est écrit dans ce cas — l'enregistrement a déjà échoué).
Future<LocalParent?> showGuardianPhoneConflictDialog({
  required BuildContext context,
  required String phoneNumber,
}) {
  return showDialog<LocalParent>(
    context: context,
    barrierColor: AppColors.bleuProfond.withValues(alpha: 0.5),
    builder: (_) => BlocProvider<ParentSearchBloc>(
      // La recherche part À L'OUVERTURE, sur le numéro refusé : aucun critère
      // n'est à ressaisir, c'est tout l'intérêt d'être arrivé ici.
      create: (_) =>
          getIt<ParentSearchBloc>()
            ..add(ParentSearchRequested(phoneNumber: phoneNumber)),
      child: _GuardianPhoneConflictDialog(phoneNumber: phoneNumber),
    ),
  );
}

class _GuardianPhoneConflictDialog extends StatefulWidget {
  final String phoneNumber;

  const _GuardianPhoneConflictDialog({required this.phoneNumber});

  @override
  State<_GuardianPhoneConflictDialog> createState() =>
      _GuardianPhoneConflictDialogState();
}

class _GuardianPhoneConflictDialogState
    extends State<_GuardianPhoneConflictDialog> {
  /// Fiche désignée. `null` tant que l'utilisateur n'a rien touché : la
  /// première remontée fait alors office de proposition (cas courant — une
  /// seule fiche porte ce numéro).
  String? _selectedId;

  LocalParent? _effectiveSelection(List<LocalParent> results) {
    if (results.isEmpty) return null;
    final id = _selectedId;
    if (id == null) return results.first;
    return results.where((p) => p.id == id).firstOrNull ?? results.first;
  }

  void _retry() => context.read<ParentSearchBloc>().add(
    ParentSearchRequested(phoneNumber: widget.phoneNumber),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final inset = size.width <= AppBreakpoints.dataTablePhoneMax
        ? AppDimensions.spacingM
        : AppDimensions.spacingL;

    return Dialog(
      backgroundColor: AppColors.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.all(inset),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: AppDimensions.guardianSearchModalMaxWidth,
          maxHeight: size.height * 0.85,
        ),
        child: EteeloDialogBody(
          // Pied à deux boutons (~72 dp) sous un en-tête de 86 : au-dessous de
          // ce seuil, tout rejoint le défilement plutôt que de déborder.
          minPinnedHeight: 260,
          header: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EteeloDialogDarkHeader(
                eyebrow: l10n.guardianPhoneConflictDialogEyebrow,
                title: l10n.guardianPhoneConflictDialogTitle,
                onClose: () => Navigator.of(context).pop(),
              ),
              const EteeloDialogGoldDivider(),
            ],
          ),
          bodyPadding: const EdgeInsets.all(AppDimensions.spacingL),
          body: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.guardianPhoneConflictDialogMessage(widget.phoneNumber),
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingL),
              _buildResults(l10n),
            ],
          ),
          footer: [_buildFooter(l10n)],
        ),
      ),
    );
  }

  Widget _buildResults(AppLocalizations l10n) {
    return BlocBuilder<ParentSearchBloc, ParentSearchState>(
      builder: (context, state) {
        return switch (state) {
          // La recherche est lancée à l'ouverture : l'état initial ne dure
          // qu'une image, et se rend comme le chargement.
          ParentSearchInitial() || ParentSearchLoading() => EteeloListSkeleton(
            rowCount: 1,
            pillCount: 0,
            semanticsLabel: l10n.guardianPhoneConflictDialogTitle,
          ),
          ParentSearchLoaded(:final results) => ParentSearchResultsList(
            results: results,
            selectable: true,
            selectedParentId: _effectiveSelection(results)?.id,
            onSelected: (parent) => setState(() => _selectedId = parent.id),
          ),
          // Numéro refusé mais fiche introuvable : la garde compare des
          // numéros normalisés là où la recherche passe par un `LIKE` sur les
          // chiffres. Le cas est improbable, jamais impossible — et sans
          // fiche à proposer, il ne reste que la correction du numéro.
          ParentSearchEmpty() => EteeloEmptyResult(
            label: l10n.guardianPhoneConflictNotFoundTitle,
            description: l10n.guardianPhoneConflictNotFoundDescription,
            minHeight: AppDimensions.guardianSearchResultsMinHeight,
            cardPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingL,
            ),
            fullWidthCard: true,
          ),
          ParentSearchError(:final message) => EteeloErrorResult(
            type: EteeloErrorType.unknown,
            title: l10n.guardianPhoneConflictDialogTitle,
            message: message,
            minHeight: AppDimensions.guardianSearchResultsMinHeight,
            cardPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacingL,
              vertical: AppDimensions.spacingL,
            ),
            primaryAction: EteeloButton.primary(
              label: l10n.guardianSearchErrorRetry,
              onPressed: _retry,
            ),
          ),
        };
      },
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return BlocBuilder<ParentSearchBloc, ParentSearchState>(
      builder: (context, state) {
        final selection = state is ParentSearchLoaded
            ? _effectiveSelection(state.results)
            : null;

        return Container(
          padding: const EdgeInsets.all(AppDimensions.spacingL),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: AppDimensions.spacingM,
            runSpacing: AppDimensions.spacingS,
            children: [
              EteeloButton.secondary(
                label: l10n.guardianPhoneConflictFixPhoneAction,
                onPressed: () => Navigator.of(context).pop(),
              ),
              EteeloButton.primary(
                label: l10n.guardianPhoneConflictUseAction,
                icon: Icons.link_rounded,
                onPressed: selection == null
                    ? null
                    : () => Navigator.of(context).pop(selection),
              ),
            ],
          ),
        );
      },
    );
  }
}
