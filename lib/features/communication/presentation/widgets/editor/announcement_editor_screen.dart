import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_channel.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/audience/announcement_reach_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_cubit.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/editor_action_bar.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/editor_form.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/editor_gestures.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/preview/announcement_preview_panel.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Ce qui a abouti, et le communiqué tel que le serveur l'a rendu.
typedef EditorDone =
    void Function(AnnouncementEditorOutcome outcome, Announcement announcement);

enum _EditorTab { write, preview }

/// L'éditeur : les sections, l'aperçu parent et la barre d'actions collante.
///
/// ≥ 1000 dp, l'aperçu est un panneau collant à droite ; en deçà, une
/// bascule « Rédiger · Aperçu parent » montre l'un ou l'autre.
class AnnouncementEditorScreen extends StatefulWidget {
  final VoidCallback onBack;
  final EditorDone onDone;
  final DateTime Function() now;

  /// Les cycles et niveaux de l'année, pour le ciblage.
  final List<SchoolLevelGroupBundle> groups;
  final String? schoolName;

  /// Faux : l'envoi part sans récapitulatif.
  final bool confirmBeforeSending;

  const AnnouncementEditorScreen({
    super.key,
    required this.onBack,
    required this.onDone,
    this.now = DateTime.now,
    this.groups = const [],
    this.schoolName,
    this.confirmBeforeSending = true,
  });

  @override
  State<AnnouncementEditorScreen> createState() =>
      _AnnouncementEditorScreenState();
}

class _AnnouncementEditorScreenState extends State<AnnouncementEditorScreen> {
  var _tab = _EditorTab.write;

  EditorGestures get _gestures => EditorGestures(
    context,
    now: widget.now,
    confirmBeforeSending: widget.confirmBeforeSending,
  );

  Future<void> _submit() async {
    final incomplete = await _gestures.submit();
    // En mode étroit, un manque se corrige dans « Rédiger ».
    if (incomplete && mounted) setState(() => _tab = _EditorTab.write);
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<AnnouncementEditorCubit, AnnouncementEditorState>(
        listenWhen: (prev, curr) =>
            curr.outcome != null && prev.outcome != curr.outcome,
        listener: (context, state) {
          final announcement = state.announcement;
          if (announcement != null) {
            widget.onDone(state.outcome!, announcement);
          }
        },
      ),
      // La portée suit l'audience ; le cubit attend un court silence.
      BlocListener<AnnouncementEditorCubit, AnnouncementEditorState>(
        listenWhen: (prev, curr) =>
            prev.content.audience != curr.content.audience,
        listener: (context, state) => context
            .read<AnnouncementReachCubit>()
            .update(state.content.audience),
      ),
    ],
    child: BlocBuilder<AnnouncementEditorCubit, AnnouncementEditorState>(
      builder: (context, state) => Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) =>
                  constraints.maxWidth >=
                      AppDimensions.communicationEditorWideMinWidth
                  ? _wide(state)
                  : _narrow(state),
            ),
          ),
          // En lecture seule, aucun geste à offrir.
          if (!state.readOnly)
            EditorActionBar(
              state: state,
              onDraft: context.read<AnnouncementEditorCubit>().saveDraft,
              onSubmit: _submit,
              onCancel: _gestures.cancel,
            ),
        ],
      ),
    ),
  );

  Widget _form(AnnouncementEditorState state) => EditorForm(
    state: state,
    onBack: widget.onBack,
    now: widget.now(),
    groups: widget.groups,
  );

  Widget _preview(AnnouncementEditorState state) =>
      BlocBuilder<AnnouncementReachCubit, AnnouncementReachState>(
        buildWhen: (prev, curr) =>
            prev.whatsappDisabled != curr.whatsappDisabled,
        builder: (context, reach) => AnnouncementPreviewPanel(
          content: state.content,
          schoolName: widget.schoolName,
          channelOff:
              reach.whatsappDisabled ||
              !state.content.channels.contains(AnnouncementChannel.whatsapp),
        ),
      );

  Widget _wide(AnnouncementEditorState state) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: _form(state),
        ),
      ),
      Container(
        width: AppDimensions.communicationPreviewPanelWidth + 2 * AppSpacing.lg,
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: AppColors.border)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _preview(state),
        ),
      ),
    ],
  );

  Widget _narrow(AnnouncementEditorState state) {
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedTabFilter<_EditorTab>(
            expand: true,
            semanticsLabel: l10n.communicationPreviewTitle,
            options: [
              SegmentedTabOption(
                label: l10n.communicationTabWrite,
                value: _EditorTab.write,
                icon: Icons.edit_outlined,
              ),
              SegmentedTabOption(
                label: l10n.communicationPreviewTitle,
                value: _EditorTab.preview,
                icon: Icons.smartphone_outlined,
              ),
            ],
            selected: _tab,
            onSelected: (tab) => setState(() => _tab = tab),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_tab == _EditorTab.write) _form(state) else _preview(state),
        ],
      ),
    );
  }
}
