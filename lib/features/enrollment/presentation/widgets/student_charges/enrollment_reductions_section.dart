import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/features/enrollment/presentation/bloc/reduction_selection_cubit.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les réductions déclarées au guichet (ADR-021 V1).
///
/// **Aucun taux affiché, et c'est une décision.** En V1 rien n'est calculé :
/// les créances restent au tarif plein. Écrire « −50 % » à côté d'un total
/// inchangé ferait passer pour un bug ce qui est le contrat de la version. On
/// coche un libellé, la déclaration part avec l'inscription, et le serveur en
/// tiendra compte quand il saura le faire.
///
/// **Pas de bouton d'enregistrement.** L'étape Frais est en lecture seule
/// (PARCOURS 21) : sa seule action est « Continuer ». Chaque clic persiste donc
/// immédiatement — une case qui attendrait une validation d'étape se perdrait
/// sans que rien ne l'annonce.
///
/// **La section s'escamote quand il n'y a rien à proposer.** Barème absent,
/// droit `finance.grid.read` manquant, serveur qui ne porte pas encore les
/// sections : trois causes, un même écran vide, et un cadre vide ferait
/// chercher au guichet ce qui manque. L'étape dit déjà ce qu'il faut sur la
/// grille tarifaire, qui est caviardée par le même droit.
class EnrollmentReductionsSection extends StatelessWidget {
  final String enrollmentId;

  /// Consultation : les cases se lisent, ne se cochent pas. **Pleine couleur**,
  /// jamais grisées — la valeur reste une information à lire (même règle que
  /// [FormerStudentCheckbox]).
  final bool isEditable;

  const EnrollmentReductionsSection({
    super.key,
    required this.enrollmentId,
    this.isEditable = true,
  });

  @override
  Widget build(BuildContext context) {
    if (enrollmentId.isEmpty) return const SizedBox.shrink();

    return BlocProvider<ReductionSelectionCubit>(
      create: (_) => getIt<ReductionSelectionCubit>()..load(enrollmentId),
      child: _EnrollmentReductionsView(
        enrollmentId: enrollmentId,
        isEditable: isEditable,
      ),
    );
  }
}

class _EnrollmentReductionsView extends StatelessWidget {
  final String enrollmentId;
  final bool isEditable;

  const _EnrollmentReductionsView({
    required this.enrollmentId,
    required this.isEditable,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ReductionSelectionCubit, ReductionSelectionState>(
      // Le chargement ne montre RIEN : pas de squelette, pas de spinner. La
      // section est un complément de l'étape, pas sa raison d'être — une zone
      // qui clignote au-dessus des créances coûterait plus d'attention qu'elle
      // n'en mérite.
      buildWhen: (previous, current) => previous != current,
      builder: (context, state) {
        if (state.status != ReductionSelectionStatus.ready || state.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.enrollmentReductionsSectionTitle,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppDimensions.spacingXS),
              for (final option in state.options)
                _ReductionCheckbox(
                  label: option.label,
                  value: state.selected.contains(option.code),
                  editable: isEditable,
                  onTap: () => context.read<ReductionSelectionCubit>().toggle(
                    enrollmentId,
                    option.code,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReductionCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final bool editable;
  final VoidCallback onTap;

  const _ReductionCheckbox({
    required this.label,
    required this.value,
    required this.editable,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      checked: value,
      enabled: editable,
      label: label,
      child: InkWell(
        onTap: editable ? onTap : null,
        borderRadius: AppRadius.brSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppDimensions.spacingXS,
          ),
          child: Row(
            children: [
              // `IgnorePointer` plutôt que `onChanged: null` : la case garde sa
              // pleine couleur en lecture seule, elle ne se grise pas.
              IgnorePointer(
                ignoring: !editable,
                child: ExcludeFocus(
                  excluding: !editable,
                  child: Checkbox(
                    value: value,
                    onChanged: (_) => onTap(),
                    activeColor: AppColors.bleuArdoise,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
