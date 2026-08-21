import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_common_widgets.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';

/// PARCOURS 9 — Popin de choix de classe.
///
/// Une seule popin sert le transfert (depuis une classe) et l'affectation
/// (depuis les non-répartis). Elle rappelle l'élève + son état, liste les
/// classes sélectionnables (effectif, capacité, G/F), marque la classe actuelle
/// « Actuelle » et désactive les classes complètes « Complet ». Au choix d'une
/// cible et validation, la réassignation est dispatchée ; le toast de résultat
/// est géré par la page (listener de réassignation).
Future<void> showClassesOrganisationReassignDialog({
  required BuildContext context,
  required ClassroomMemberReassignIntent intent,
  required List<ClassroomReassignOption> options,
  required String schoolLevelId,
}) async {
  final selectedTargetId = await showDialog<String>(
    context: context,
    barrierColor: AppColors.bleuProfond.withValues(alpha: 0.5),
    builder: (_) => _ReassignDialog(intent: intent, options: options),
  );

  if (!context.mounted ||
      selectedTargetId == null ||
      selectedTargetId.isEmpty) {
    return;
  }

  final academicYearId =
      context.read<AcademicYearContextBloc>().state.context?.academicYear.id ??
      '';

  final bloc = context.read<ClassroomOfflineBloc>();
  final fromClassroomId = intent.classroomId;
  if (fromClassroomId != null) {
    // TRANSFERT (A→B, même niveau) : OFFLINE — événement + outbox, composition à
    // la lecture. Le miroir n'est jamais muté ici.
    bloc.add(
      MemberTransferRequested(
        studentId: intent.studentId,
        fromClassroomId: fromClassroomId,
        toClassroomId: selectedTargetId,
        schoolLevelId: schoolLevelId,
        academicYearId: academicYearId,
      ),
    );
  } else {
    // AFFECTATION d'un non-réparti : ONLINE (distribution, ADR-004) — un
    // non-réparti n'existe pas dans le miroir offline, donc pas d'événement.
    // Le POST d'affectation identifie l'élève par son dossier d'inscription :
    // hors mode affectation l'intent ne le porte pas, on n'émet alors rien
    // plutôt que d'envoyer une identité que le serveur ne reconnaîtrait pas.
    final enrollmentId = intent.enrollmentId;
    if (enrollmentId == null || enrollmentId.isEmpty) {
      return;
    }
    bloc.add(
      MemberAssignRequested(
        enrollmentId: enrollmentId,
        targetClassroomId: selectedTargetId,
        academicYearId: academicYearId,
      ),
    );
  }
}

class _ReassignDialog extends StatefulWidget {
  final ClassroomMemberReassignIntent intent;
  final List<ClassroomReassignOption> options;

  const _ReassignDialog({required this.intent, required this.options});

  @override
  State<_ReassignDialog> createState() => _ReassignDialogState();
}

class _ReassignDialogState extends State<_ReassignDialog> {
  String? _selectedId;

  bool get _isTransfer => widget.intent.classroomId != null;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.sizeOf(context);
    final maxHeight = size.height * 0.88;
    // Sur petit écran, on réduit les marges de la popin pour récupérer de la
    // largeur utile (sinon le contenu est trop comprimé).
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
          maxWidth: AppDimensions.classesReassignModalMaxWidth,
          maxHeight: maxHeight,
        ),
        // Coquille commune (B-9) — cf. `EteeloDialogBody`. Aucun champ, mais
        // cette modale s'ouvre depuis un écran où un clavier peut être levé, et
        // ses deux zones figées (en-tête + pied à deux actions) sont exactement
        // ce qui déborde alors.
        child: EteeloDialogBody(
          // En-tête (~90) + deux filets + pied à deux actions, empilé en
          // colonne sous 420 dp de large.
          minPinnedHeight: 300,
          header: _buildHeader(l10n),
          headerDividers: const [Divider(height: 1, color: AppColors.border)],
          bodyPadding: const EdgeInsets.all(AppDimensions.spacingL),
          // ⚠️ Liste **inerte** : le socle fournit le défilement dans les deux
          // dispositions, et `ScrollView` fige son `physics` dans son
          // constructeur — une liste laissée maîtresse gagnerait l'arène des
          // gestes en tant que `Scrollable` le plus intérieur sans avoir rien à
          // faire défiler, et le doigt ne déplacerait plus rien.
          body: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: widget.options.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppDimensions.spacingS),
            itemBuilder: (context, index) {
              final option = widget.options[index];
              final isCurrent =
                  widget.intent.classroomId != null &&
                  option.id == widget.intent.classroomId;
              return _ClassChoiceTile(
                option: option,
                isCurrent: isCurrent,
                selected: _selectedId == option.id,
                onSelect: (isCurrent || option.isFull)
                    ? null
                    : () => setState(() => _selectedId = option.id),
              );
            },
          ),
          footer: [
            const Divider(height: 1, color: AppColors.border),
            _buildFooter(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final eyebrow = _isTransfer
        ? l10n.classesOrganisationTransferDialogTitle
        : l10n.classesOrganisationAssignDialogTitle;
    final stateLabel = _isTransfer
        ? l10n.classesReassignCurrentClassState
        : l10n.classesReassignUnassignedState;
    final stateColor = _isTransfer ? AppColors.bleuArdoise : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  eyebrow.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.terreCuite,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              StudentAvatar(
                firstName: widget.intent.studentFirstName,
                lastName: widget.intent.studentLastName,
                studentId: widget.intent.studentId,
                size: AvatarSize.lg,
              ),
              const SizedBox(width: AppDimensions.spacingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.intent.studentDisplayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppDimensions.spacingXS),
                    ClassesOrganisationGenderPill(
                      label: stateLabel,
                      color: stateColor,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              ClassesOrganisationGenderMarker(
                gender: widget.intent.studentGender,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(AppLocalizations l10n) {
    final actionLabel = _isTransfer
        ? l10n.classesOrganisationTransferAction
        : l10n.classesOrganisationAssignAction;

    final cancel = TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(l10n.cancel),
    );
    // Gel READ_ONLY (ADR-010) : valider la réaffectation déclenche l'écriture
    // chez l'appelant — le tick de fraîcheur peut basculer le mode pendant que
    // le dialog est ouvert. « Annuler » (navigation) reste libre.
    final action = SessionWriteGate(
      child: FilledButton.icon(
        onPressed: _selectedId == null
            ? null
            : () => Navigator.of(context).pop(_selectedId),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.bleuArdoise,
          foregroundColor: AppColors.blancCasse,
          minimumSize: const Size(0, AppDimensions.minTouchTarget),
          shape: const StadiumBorder(),
        ),
        icon: Icon(_isTransfer ? Icons.swap_horiz_rounded : Icons.add_rounded),
        label: Text(actionLabel),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Petit écran : les deux boutons s'empilent (action en tête, pleine
          // largeur) plutôt que de déborder sur une seule ligne.
          if (constraints.maxWidth < AppBreakpoints.financeModalFooterRowMin) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                action,
                const SizedBox(height: AppDimensions.spacingS),
                cancel,
              ],
            );
          }
          return Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              cancel,
              const SizedBox(width: AppDimensions.spacingS),
              action,
            ],
          );
        },
      ),
    );
  }
}

class _ClassChoiceTile extends StatelessWidget {
  final ClassroomReassignOption option;
  final bool isCurrent;
  final bool selected;
  final VoidCallback? onSelect;

  const _ClassChoiceTile({
    required this.option,
    required this.isCurrent,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final disabled = onSelect == null;

    final String? badgeLabel;
    final Color? badgeColor;
    if (isCurrent) {
      badgeLabel = l10n.classesReassignCurrentBadge;
      badgeColor = AppColors.bleuArdoise;
    } else if (option.isFull) {
      badgeLabel = l10n.classesReassignFullBadge;
      badgeColor = AppColors.danger;
    } else {
      badgeLabel = null;
      badgeColor = null;
    }

    // Étiquette lecteur d'écran : classe + effectif/capacité/G-F + état.
    final semanticLabel = [
      l10n.classesDistributionClassLabel(option.name),
      l10n.classesReassignOptionStats(
        option.totalCount,
        option.capacity,
        option.maleCount,
        option.femaleCount,
      ),
      ?badgeLabel,
    ].join(', ');

    final tile = Opacity(
      opacity: disabled ? 0.55 : 1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSelect,
          borderRadius: AppRadius.brMd,
          child: Container(
            padding: const EdgeInsets.all(AppDimensions.spacingM),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.bleuArdoise.withValues(alpha: 0.06)
                  : AppColors.surface,
              borderRadius: AppRadius.brMd,
              border: Border.all(
                color: selected ? AppColors.bleuArdoise : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                _RadioDot(selected: selected, disabled: disabled),
                const SizedBox(width: AppDimensions.spacingM),
                _LetterBadge(code: option.name),
                const SizedBox(width: AppDimensions.spacingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.classesDistributionClassLabel(option.name),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyStrong.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.spacingXS),
                      Text(
                        l10n.classesReassignOptionStats(
                          option.totalCount,
                          option.capacity,
                          option.maleCount,
                          option.femaleCount,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badgeLabel != null && badgeColor != null) ...[
                  const SizedBox(width: AppDimensions.spacingS),
                  ClassesOrganisationGenderPill(
                    label: badgeLabel,
                    color: badgeColor,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      button: true,
      inMutuallyExclusiveGroup: true,
      selected: selected,
      enabled: !disabled,
      label: semanticLabel,
      onTap: onSelect,
      child: ExcludeSemantics(child: tile),
    );
  }
}

class _RadioDot extends StatelessWidget {
  final bool selected;
  final bool disabled;

  const _RadioDot({required this.selected, required this.disabled});

  @override
  Widget build(BuildContext context) {
    final color = disabled
        ? AppColors.stateDisabled
        : (selected ? AppColors.bleuArdoise : AppColors.border);
    return Container(
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: selected
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bleuArdoise,
              ),
            )
          : null,
    );
  }
}

class _LetterBadge extends StatelessWidget {
  final String code;

  const _LetterBadge({required this.code});

  @override
  Widget build(BuildContext context) {
    final letter = code.trim().isEmpty
        ? '?'
        : code.trim().substring(0, 1).toUpperCase();
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.bleuProfond, AppColors.bleuArdoise],
        ),
      ),
      child: Text(
        letter,
        style: AppTextStyles.bodyStrong.copyWith(
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
