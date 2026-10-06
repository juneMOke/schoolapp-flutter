import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/capture/captured_document.dart';
import 'package:school_app_flutter/core/capture/document_capture_policy.dart';
import 'package:school_app_flutter/core/components/capture/document_capture_flow.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/chapitre_enums.dart';
import 'package:school_app_flutter/features/course_programme/domain/entities/ressource_draft.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/ressource_visual.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/course_programme/presentation/helpers/programme_layout.dart';

/// Le brouillon d'une ressource, en ligne sous la liste (spec §5) : le type
/// (groupe radio), l'intitulé, puis l'adresse, la référence ou le fichier.
/// « Ajouter la ressource » reste désactivé tant que le brouillon n'est pas
/// valide ; le fichier est vérifié (type, 10 Mo) dès qu'il est choisi.
class RessourceDraftPanel extends StatefulWidget {
  final String Function() newId;
  final ValueChanged<RessourceDraft> onAdd;
  final VoidCallback onCancel;

  const RessourceDraftPanel({
    super.key,
    required this.newId,
    required this.onAdd,
    required this.onCancel,
  });

  @override
  State<RessourceDraftPanel> createState() => _RessourceDraftPanelState();
}

class _RessourceDraftPanelState extends State<RessourceDraftPanel> {
  static const DocumentCapturePolicy _policy =
      DocumentCapturePolicy.courseResource;

  final _nom = TextEditingController();
  final _url = TextEditingController();
  final _reference = TextEditingController();
  RessourceType _type = RessourceType.document;
  CapturedDocument? _file;

  @override
  void dispose() {
    _nom.dispose();
    _url.dispose();
    _reference.dispose();
    super.dispose();
  }

  RessourceDraft _draft() => RessourceDraft(
    id: widget.newId(),
    type: _type,
    nom: _nom.text.trim(),
    url: _type == RessourceType.lien ? _url.text.trim() : null,
    reference: _type == RessourceType.manuel ? _reference.text.trim() : null,
    bytes: _type == RessourceType.document ? _file?.bytes : null,
    mimeType: _type == RessourceType.document ? _file?.mimeType.value : null,
    fileName: _type == RessourceType.document ? _file?.fileName : null,
    sha256: _type == RessourceType.document ? _file?.sha256Hex : null,
  );

  Future<void> _chooseFile() async {
    final l10n = AppLocalizations.of(context)!;
    final file = await GetIt.instance<DocumentCaptureFlow>().run(
      context,
      title: l10n.ressourceCaptureTitle,
      policy: _policy,
    );
    if (!mounted || file == null) return;
    setState(() {
      _file = file;
      final name = file.fileName;
      if (_nom.text.trim().isEmpty && name != null) {
        final dot = name.lastIndexOf('.');
        _nom.text = dot > 0 ? name.substring(0, dot) : name;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final urlText = _url.text.trim();
    final urlInvalid =
        urlText.isNotEmpty && !RessourceDraft.urlPattern.hasMatch(urlText);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TypeChoice(
            value: _type,
            onChanged: (type) => setState(() => _type = type),
          ),
          const SizedBox(height: AppSpacing.md),
          EteeloTextInput(
            controller: _nom,
            label: l10n.ressourceNomLabel,
            placeholder: switch (_type) {
              RessourceType.document => l10n.ressourceNomHintDocument,
              RessourceType.lien => l10n.ressourceNomHintLien,
              RessourceType.manuel => l10n.ressourceNomHintManuel,
            },
            capitalization: EteeloTextCapitalization.sentence,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          ...switch (_type) {
            RessourceType.lien => [
              EteeloTextInput(
                controller: _url,
                label: l10n.ressourceUrlLabel,
                placeholder: l10n.ressourceUrlHint,
                capitalization: EteeloTextCapitalization.none,
                errorText: urlInvalid ? l10n.ressourceUrlInvalid : null,
                onChanged: (_) => setState(() {}),
              ),
            ],
            RessourceType.manuel => [
              EteeloTextInput(
                controller: _reference,
                label: l10n.ressourceReferenceLabel,
                placeholder: l10n.ressourceReferenceHint,
                capitalization: EteeloTextCapitalization.none,
                onChanged: (_) => setState(() {}),
              ),
            ],
            RessourceType.document => [_filePicker(l10n)],
          },
          const SizedBox(height: AppSpacing.md),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              EteeloButton.secondary(
                label: l10n.cancel,
                onPressed: widget.onCancel,
                fullWidth: false,
              ),
              EteeloButton.primary(
                label: l10n.ressourceAddConfirm,
                icon: Icons.check_rounded,
                onPressed: _draft().isValid
                    ? () => widget.onAdd(_draft())
                    : null,
                fullWidth: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filePicker(AppLocalizations l10n) {
    final file = _file;
    return Row(
      children: [
        TextButton.icon(
          onPressed: _chooseFile,
          icon: const Icon(
            Icons.upload_file_rounded,
            size: ProgrammeLayout.iconMedium,
          ),
          label: Text(
            file == null ? l10n.ressourceChooseFile : l10n.ressourceReplaceFile,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            file?.fileName ?? l10n.ressourceFileHint(_policy.maxMegabytes),
            style: AppTypography.bodySmall.copyWith(
              color: file == null ? AppColors.textMuted : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _TypeChoice extends StatelessWidget {
  final RessourceType value;
  final ValueChanged<RessourceType> onChanged;

  const _TypeChoice({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      label: l10n.ressourceTypeRadioLabel,
      child: SegmentedButton<RessourceType>(
        segments: [
          for (final type in RessourceType.values)
            ButtonSegment(
              value: type,
              icon: Icon(
                RessourceVisual.icon(type),
                size: ProgrammeLayout.iconSmall,
              ),
              label: Text(RessourceVisual.label(l10n, type)),
            ),
        ],
        selected: {value},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.single),
      ),
    );
  }
}
