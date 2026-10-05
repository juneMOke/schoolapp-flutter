import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_body.dart';
import 'package:school_app_flutter/core/components/dialogs/eteelo_dialog_dark_header.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_detail_args.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_edit.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/chapitre_form_model.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/form/chapitre_form_sections.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/form/chapitre_objectifs_field.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/form/chapitre_planning_fields.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/form/chapitre_statut_picker.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/form/chapitre_strategies_field.dart';
import 'package:school_app_flutter/features/course_programme/presentation/widgets/ressources/ressources_editor.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ouvre la modale « Nouveau / Modifier le chapitre » ; rend l'édition, ou
/// `null` si l'on renonce. Le scrim ne ferme pas : une saisie est du travail
/// non enregistré. Sous 600 dp, la modale occupe tout l'écran.
Future<ChapitreEdit?> showChapitreFormDialog(
  BuildContext context, {
  required CoursDetailArgs cours,
  required Chapitre? chapitre,
  required List<SousPeriodeOption> sousPeriodes,
  required String Function() newId,
}) => showDialog<ChapitreEdit>(
  context: context,
  barrierDismissible: false,
  builder: (_) => ChapitreFormDialog(
    cours: cours,
    chapitre: chapitre,
    sousPeriodes: sousPeriodes,
    newId: newId,
  ),
);

/// La modale d'un chapitre (spec §4) : trois groupes numérotés. Rien ne
/// devient rouge pendant la frappe : le titre se juge à la première
/// soumission. Le contenu rédigé et les notes ne s'éditent pas ici, mais sur
/// le détail du chapitre.
class ChapitreFormDialog extends StatefulWidget {
  final CoursDetailArgs cours;
  final Chapitre? chapitre;
  final List<SousPeriodeOption> sousPeriodes;
  final String Function() newId;

  const ChapitreFormDialog({
    super.key,
    required this.cours,
    required this.chapitre,
    required this.sousPeriodes,
    required this.newId,
  });

  @override
  State<ChapitreFormDialog> createState() => _ChapitreFormDialogState();
}

class _ChapitreFormDialogState extends State<ChapitreFormDialog> {
  late final _model = ChapitreFormModel(
    coursId: widget.cours.coursId,
    base: widget.chapitre,
    newId: widget.newId,
    defaultSousPeriodeId: widget.sousPeriodes.firstOrNull?.id,
  );
  bool _touched = false;

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _submit() {
    setState(() => _touched = true);
    final edit = _model.result();
    if (edit != null) Navigator.of(context).pop(edit);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = EteeloDialogBody(
      header: EteeloDialogDarkHeader(
        eyebrow: l10n.chapitreFormEyebrow(
          widget.cours.brancheNom,
          widget.cours.classroomName,
        ),
        title: _model.isNew
            ? l10n.chapitreFormNewTitle
            : l10n.chapitreFormEditTitle,
        onClose: () => Navigator.of(context).pop(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: _groups(l10n),
      ),
      footer: [_Footer(isNew: _model.isNew, onSubmit: _submit)],
    );
    if (MediaQuery.sizeOf(context).width < ProgrammeLayout.compactRowBelow) {
      return Dialog.fullscreen(child: body);
    }
    return Dialog(
      insetPadding: const EdgeInsets.all(AppDimensions.spacingL),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.brCard),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ProgrammeLayout.formDialogMaxWidth,
        ),
        child: body,
      ),
    );
  }

  Widget _groups(AppLocalizations l10n) {
    final titreError = _touched ? _model.titreError : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChapitreFormGroup(
          numero: 1,
          title: l10n.chapitreFormGroupIdentification,
          children: [
            EteeloTextInput(
              controller: _model.titre,
              label: l10n.chapitreFormTitreLabel,
              placeholder: l10n.chapitreFormTitreHint,
              required: true,
              capitalization: EteeloTextCapitalization.sentence,
              errorText: switch (titreError) {
                TitreError.required => l10n.chapitreFormTitreRequired,
                TitreError.tooShort => l10n.chapitreFormTitreTooShort,
                null => null,
              },
            ),
            EteeloTextInput(
              controller: _model.resume,
              label: l10n.chapitreFormResumeLabel,
              placeholder: l10n.chapitreFormResumeHint,
              keyboardType: EteeloTextInputType.multiline,
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ChapitreFormGroup(
          numero: 2,
          title: l10n.chapitreFormGroupPedagogie,
          children: [
            ChapitreObjectifsField(model: _model, onChanged: _refresh),
            ChapitreStrategiesField(model: _model, onChanged: _refresh),
            RessourcesEditor(
              model: _model,
              newId: widget.newId,
              onChanged: _refresh,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ChapitreFormGroup(
          numero: 3,
          title: l10n.chapitreFormGroupPlanification,
          children: [
            ChapitreFormLabel(label: l10n.chapitreFormStatutLabel),
            ChapitreStatutPicker(
              value: _model.statut,
              onChanged: (statut) => setState(() => _model.statut = statut),
            ),
            ChapitrePlanningFields(
              model: _model,
              sousPeriodes: widget.sousPeriodes,
              touched: _touched,
              onChanged: _refresh,
            ),
          ],
        ),
      ],
    );
  }
}

class _Footer extends StatelessWidget {
  final bool isNew;
  final VoidCallback onSubmit;

  const _Footer({required this.isNew, required this.onSubmit});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '* ',
                  style: TextStyle(color: AppColors.error),
                ),
                TextSpan(text: l10n.chapitreFormRequiredLegend),
              ],
            ),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: EteeloButton.secondary(
                  label: l10n.cancel,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: EteeloButton.primary(
                  label: isNew
                      ? l10n.chapitreFormCreate
                      : l10n.chapitreFormSave,
                  icon: Icons.check_rounded,
                  onPressed: onSubmit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
