import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/class_journal/domain/entities/journal_fields.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_cubit.dart';
import 'package:school_app_flutter/features/class_journal/presentation/bloc/journal_entry_state.dart';
import 'package:school_app_flutter/features/class_journal/presentation/helpers/journal_field.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Les sept champs du cahier : six en grille (deux colonnes dès qu'il y a la
/// place), l'observation en pleine largeur. Après une tentative refusée, le
/// premier champ requis vide prend le focus.
class JournalFieldsGrid extends StatefulWidget {
  const JournalFieldsGrid({super.key});

  @override
  State<JournalFieldsGrid> createState() => _JournalFieldsGridState();
}

class _JournalFieldsGridState extends State<JournalFieldsGrid> {
  late final Map<JournalField, TextEditingController> _controllers = {
    for (final field in JournalField.values) field: TextEditingController(),
  };
  late final Map<JournalField, FocusNode> _focus = {
    for (final field in JournalField.values) field: FocusNode(),
  };

  @override
  void initState() {
    super.initState();
    _sync(context.read<JournalEntryCubit>().state.fields);
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    for (final f in _focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  void _sync(JournalFields fields) {
    for (final MapEntry(key: field, value: controller)
        in _controllers.entries) {
      final value = field.valueOf(fields);
      if (controller.text != value) controller.text = value;
    }
  }

  void _focusFirstMissing(JournalFields fields) {
    for (final field in JournalField.values) {
      if (field.isRequired && field.valueOf(fields).trim().isEmpty) {
        _focus[field]!.requestFocus();
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<JournalEntryCubit, JournalEntryState>(
          listenWhen: (prev, curr) => prev.revision != curr.revision,
          listener: (context, state) => _sync(state.fields),
        ),
        BlocListener<JournalEntryCubit, JournalEntryState>(
          listenWhen: (prev, curr) => prev.refusals != curr.refusals,
          listener: (context, state) => _focusFirstMissing(state.fields),
        ),
      ],
      child: BlocBuilder<JournalEntryCubit, JournalEntryState>(
        buildWhen: (prev, curr) =>
            prev.showErrors != curr.showErrors ||
            prev.isBusy != curr.isBusy ||
            (curr.showErrors && prev.fields != curr.fields),
        builder: (context, state) => LayoutBuilder(
          builder: (context, constraints) {
            final twoColumns =
                constraints.maxWidth >=
                2 * AppDimensions.journalFieldMinWidth + AppSpacing.md;
            final half = twoColumns
                ? (constraints.maxWidth - AppSpacing.md) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.md,
              children: [
                for (final field in JournalField.values)
                  SizedBox(
                    width: field == JournalField.observation
                        ? constraints.maxWidth
                        : half,
                    child: _input(context, state, field),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _input(
    BuildContext context,
    JournalEntryState state,
    JournalField field,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final missing =
        state.showErrors &&
        field.isRequired &&
        field.valueOf(state.fields).trim().isEmpty;
    return EteeloTextInput(
      controller: _controllers[field]!,
      focusNode: _focus[field],
      label: _label(field, l10n),
      placeholder: _placeholder(field, l10n),
      keyboardType: EteeloTextInputType.multiline,
      minLines: 2,
      maxLines: 4,
      required: field.isRequired,
      enabled: !state.isBusy,
      errorText: missing ? _missing(field, l10n) : null,
      inputFormatters: [
        LengthLimitingTextInputFormatter(JournalFields.maxLength),
      ],
      onChanged: (value) =>
          context.read<JournalEntryCubit>().updateField(field, value),
    );
  }

  static String _label(JournalField field, AppLocalizations l10n) =>
      switch (field) {
        JournalField.cb => l10n.journalFieldCbLabel,
        JournalField.contenu => l10n.journalFieldContenuLabel,
        _ => field.label(l10n),
      };

  static String? _placeholder(JournalField field, AppLocalizations l10n) =>
      switch (field) {
        JournalField.objectif => l10n.journalPlaceholderObjectif,
        JournalField.ressources => l10n.journalPlaceholderRessources,
        JournalField.observation => l10n.journalPlaceholderObservation,
        _ => null,
      };

  static String _missing(JournalField field, AppLocalizations l10n) =>
      field == JournalField.objectif
      ? l10n.journalRequiredObjectif
      : l10n.journalRequiredContenu;
}
