import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/status/eteelo_notice.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_audience.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_category.dart';
import 'package:school_app_flutter/features/communication/domain/entities/announcement_content.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_validation.dart';
import 'package:school_app_flutter/features/communication/domain/services/announcement_variables.dart';
import 'package:school_app_flutter/features/communication/presentation/bloc/editor/announcement_editor_state.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/category_picker.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/counted_text_field.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/editor_section_card.dart';
import 'package:school_app_flutter/features/communication/presentation/widgets/editor/variable_insert_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Section 1 — ce que les parents liront : catégorie, titre, message.
///
/// Les contrôleurs vivent ici : l'insertion d'une variable se fait **au
/// curseur**, que seul le champ connaît.
class ContentSection extends StatefulWidget {
  final AnnouncementEditorState state;
  final ValueChanged<AnnouncementCategory> onCategory;
  final ValueChanged<String> onTitle;
  final ValueChanged<String> onBody;

  const ContentSection({
    super.key,
    required this.state,
    required this.onCategory,
    required this.onTitle,
    required this.onBody,
  });

  @override
  State<ContentSection> createState() => _ContentSectionState();
}

class _ContentSectionState extends State<ContentSection> {
  late final TextEditingController _title = TextEditingController(
    text: widget.state.content.title,
  );
  late final TextEditingController _body = TextEditingController(
    text: widget.state.content.body,
  );
  final FocusNode _bodyFocus = FocusNode();

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _bodyFocus.dispose();
    super.dispose();
  }

  void _insert(AnnouncementVariable variable) {
    final selection = _body.selection;
    final inserted = AnnouncementVariables.insert(
      _body.text,
      variable,
      start: selection.start,
      end: selection.end,
    );
    if (inserted.text.characters.length > AnnouncementContent.bodyMaxLength) {
      return;
    }
    _body.value = TextEditingValue(
      text: inserted.text,
      selection: TextSelection.collapsed(offset: inserted.cursor),
    );
    widget.onBody(inserted.text);
    _bodyFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = widget.state;
    final content = state.content;
    final locked = state.isLocked;
    final overdue = content.audience is OverdueAudience;
    return EditorSectionCard(
      number: 1,
      title: l10n.communicationSectionContent,
      subtitle: l10n.communicationSectionContentHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CategoryPicker(
            value: content.category,
            onChanged: locked ? null : widget.onCategory,
          ),
          const SizedBox(height: AppSpacing.lg),
          CountedTextField(
            controller: _title,
            label: l10n.communicationTitleLabel,
            placeholder: l10n.communicationTitlePlaceholder,
            maxLength: AnnouncementContent.titleMaxLength,
            enabled: !locked,
            errorText: _titleError(l10n, state),
            onChanged: widget.onTitle,
          ),
          const SizedBox(height: AppSpacing.md),
          VariableInsertBar(
            amountAllowed: overdue,
            onInsert: locked ? null : _insert,
          ),
          const SizedBox(height: AppSpacing.sm),
          CountedTextField(
            controller: _body,
            focusNode: _bodyFocus,
            label: l10n.communicationBodyLabel,
            placeholder: l10n.communicationBodyPlaceholder,
            maxLength: AnnouncementContent.bodyMaxLength,
            multiline: true,
            lines: AppDimensions.communicationMessageLines,
            enabled: !locked,
            errorText: _bodyError(l10n, state),
            hint: l10n.communicationBodyHint,
            onChanged: widget.onBody,
          ),
          // L'ambre dès que le montant apparaît hors des retards : avant même
          // le premier essai d'envoi.
          if (AnnouncementValidation.amountMisplaced(content)) ...[
            const SizedBox(height: AppSpacing.sm),
            EteeloNotice.warning(l10n.communicationAmountMisplaced),
          ],
        ],
      ),
    );
  }

  static String? _titleError(
    AppLocalizations l10n,
    AnnouncementEditorState s,
  ) => s.hasIssueOn(AnnouncementField.title)
      ? l10n.communicationTitleRequired
      : null;

  static String? _bodyError(AppLocalizations l10n, AnnouncementEditorState s) {
    if (!s.hasIssueOn(AnnouncementField.body)) return null;
    final unknown = AnnouncementVariables.unknownIn(
      '${s.content.title} ${s.content.body}',
    );
    if (unknown.isNotEmpty) {
      return l10n.communicationUnknownVariable(
        unknown.join(', '),
        AnnouncementVariable.values.map((v) => v.token).join(', '),
      );
    }
    if (s.content.body.trim().isEmpty) return l10n.communicationBodyRequired;
    if (AnnouncementValidation.amountMisplaced(s.content)) {
      return l10n.communicationAmountMisplaced;
    }
    return l10n.communicationBodyRefused;
  }
}
