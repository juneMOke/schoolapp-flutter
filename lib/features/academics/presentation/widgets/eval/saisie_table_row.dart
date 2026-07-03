import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/components/avatars/student_avatar.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/note_eleve.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_note.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/academics_notation_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/note_saisie_visuals.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/saisie_draft_controller.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/detail/cours_notation_atoms.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/absence_toggle.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Une ligne de saisie en mode Tableau (spec §8) : n° · identité · champ note
/// (suffixe /max, Entrée → élève suivant) · bascule d'absence · pastille de
/// statut. Possède son propre [TextEditingController], synchronisé au brouillon
/// partagé (le [FocusNode] est fourni par le tableau pour le chaînage).
class SaisieTableRow extends StatefulWidget {
  final int position;
  final NoteEleve student;
  final SaisieDraftController draft;
  final FocusNode focusNode;
  final VoidCallback? onSubmitted;
  final bool inputsEnabled;

  const SaisieTableRow({
    super.key,
    required this.position,
    required this.student,
    required this.draft,
    required this.focusNode,
    required this.inputsEnabled,
    this.onSubmitted,
  });

  @override
  State<SaisieTableRow> createState() => _SaisieTableRowState();
}

class _SaisieTableRowState extends State<SaisieTableRow> {
  late final TextEditingController _controller;

  // Dernières valeurs propres à CETTE ligne, pour ne se reconstruire que si son
  // état change (le brouillon notifie tout le monde à chaque frappe).
  late String _lastRaw;
  late StatutNote? _lastAbsence;

  String get _id => widget.student.studentId;

  @override
  void initState() {
    super.initState();
    _lastRaw = widget.draft.rawOf(_id);
    _lastAbsence = widget.draft.absenceOf(_id);
    _controller = TextEditingController(text: _lastRaw);
    widget.draft.addListener(_syncFromDraft);
  }

  @override
  void dispose() {
    widget.draft.removeListener(_syncFromDraft);
    _controller.dispose();
    super.dispose();
  }

  /// Recale le champ si le brouillon a changé « de l'extérieur » (ex. une
  /// absence a effacé les points) et rafraîchit les visuels dérivés — mais
  /// seulement si l'état de CETTE ligne a réellement bougé (évite un rebuild de
  /// toutes les lignes à chaque frappe : raw+absence déterminent tout l'affichage).
  void _syncFromDraft() {
    final raw = widget.draft.rawOf(_id);
    final absence = widget.draft.absenceOf(_id);
    if (raw == _lastRaw && absence == _lastAbsence) return;
    _lastRaw = raw;
    _lastAbsence = absence;
    if (_controller.text != raw) {
      _controller.value = TextEditingValue(
        text: raw,
        selection: TextSelection.collapsed(offset: raw.length),
      );
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final draft = widget.draft;
    final absence = draft.absenceOf(_id);
    final statut = draft.statutFor(_id);
    final hasError = draft.hasErrorFor(_id);
    final fieldEnabled = widget.inputsEnabled && absence == null;

    final zebra = widget.position.isEven
        ? AppColors.surface
        : AppColors.surfaceRaised;

    return Container(
      decoration: BoxDecoration(
        color: zebra,
        border: widget.position == 1
            ? null
            : const Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = _Identity(
            student: widget.student,
            position: widget.position,
          );
          final field = _NoteField(
            controller: _controller,
            focusNode: widget.focusNode,
            enabled: fieldEnabled,
            hasError: hasError,
            maxPoints: draft.maxPoints,
            onChanged: (v) => draft.setRaw(_id, v),
            onSubmitted: widget.onSubmitted,
          );
          final toggle = AbsenceToggle(
            selected: absence,
            enabled: widget.inputsEnabled,
            onToggle: (a) => draft.toggleAbsence(_id, a),
          );
          final badge = _StatusColumn(
            l10n: l10n,
            statut: statut,
            hasError: hasError,
            maxPoints: draft.maxPoints,
          );

          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                identity,
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [field, toggle, badge],
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: AppSpacing.md),
              field,
              const SizedBox(width: AppSpacing.sm),
              toggle,
              const SizedBox(width: AppSpacing.md),
              badge,
            ],
          );
        },
      ),
    );
  }
}

class _Identity extends StatelessWidget {
  final NoteEleve student;
  final int position;

  const _Identity({required this.student, required this.position});

  @override
  Widget build(BuildContext context) {
    final primary = [
      student.lastName,
      student.middleName ?? '',
    ].where((s) => s.trim().isNotEmpty).join(' ');
    return Row(
      children: [
        SizedBox(
          width: 22,
          child: Text(
            position.toString().padLeft(2, '0'),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textMuted,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        StudentAvatar(
          firstName: student.firstName,
          lastName: student.lastName,
          studentId: student.studentId,
          size: 30,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primary.isEmpty ? student.firstName : primary,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                student.firstName,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NoteField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final bool hasError;
  final double maxPoints;
  final ValueChanged<String> onChanged;
  final VoidCallback? onSubmitted;

  const _NoteField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hasError,
    required this.maxPoints,
    required this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? AppColors.academicsScoreFail
        : AppColors.border;
    final borderWidth = hasError ? 2.0 : 1.0;
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
      borderRadius: AppRadius.brSm,
      borderSide: BorderSide(color: c, width: w),
    );
    return SizedBox(
      width: 150,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        textInputAction: TextInputAction.next,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmitted?.call(),
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: enabled ? AppColors.surfaceRaised : AppColors.surfaceAlt,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 11,
            vertical: 9,
          ),
          suffixText: '/${formatPoints(maxPoints)}',
          suffixStyle: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          enabledBorder: border(borderColor, borderWidth),
          focusedBorder: border(
            hasError ? AppColors.academicsScoreFail : AppColors.bleuArdoise,
            hasError ? 2.0 : 1.5,
          ),
          disabledBorder: border(AppColors.border, 1),
          border: border(borderColor, borderWidth),
        ),
      ),
    );
  }
}

class _StatusColumn extends StatelessWidget {
  final AppLocalizations l10n;
  final StatutNote statut;
  final bool hasError;
  final double maxPoints;

  const _StatusColumn({
    required this.l10n,
    required this.statut,
    required this.hasError,
    required this.maxPoints,
  });

  @override
  Widget build(BuildContext context) {
    final visual = noteStatutVisual(statut);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NotationPill(
          color: visual.color,
          soft: visual.soft,
          label: noteStatutLabel(l10n, statut),
        ),
        if (hasError) ...[
          const SizedBox(height: 3),
          Text(
            l10n.evalNoteMaxError(formatPoints(maxPoints)),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.academicsScoreFail,
            ),
          ),
        ],
      ],
    );
  }
}
