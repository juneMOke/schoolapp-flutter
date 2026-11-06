import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/components/controls/segmented_tab_filter.dart';
import 'package:school_app_flutter/core/components/keyboard/search_shortcuts.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/export/csv_writer.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_elevation.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/cotes/domain/entities/cote_classe.dart';
import 'package:school_app_flutter/features/cotes/domain/services/cote_calculator.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_bloc.dart';
import 'package:school_app_flutter/features/cotes/presentation/bloc/cote_saisie_state.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/list/cote_student_query.dart';
import 'package:school_app_flutter/features/cotes/presentation/widgets/list/cote_student_tile.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Vrai si [eleve] répond à la recherche et au filtre : contient, sans casse ni
/// accents, sur « nom post-nom prénom ».
bool coteStudentMatches({
  required CoteEleve eleve,
  required CoteEleveCalc? calc,
  required String query,
  required CoteStudentFilter filter,
}) {
  final needle = _fold(query.trim());
  if (needle.isNotEmpty && !_fold(eleve.fullName).contains(needle)) {
    return false;
  }
  final complete = calc?.complete ?? false;
  return switch (filter) {
    CoteStudentFilter.all => true,
    CoteStudentFilter.todo => !complete,
    CoteStudentFilter.done => complete,
  };
}

String _fold(String value) => CsvWriter.removeDiacritics(value).toLowerCase();

/// La liste des élèves : recherche et filtre sont de l'état d'écran, pas du
/// métier, tenu par [query] au-dessus d'elle. Ctrl+F (ou « / ») va à la
/// recherche ; Échap la vide.
class CoteStudentPanel extends StatefulWidget {
  final CoteStudentQuery query;

  /// Appelé au passage à un autre élève (la frappe en attente part).
  final VoidCallback? onStudentChanged;

  const CoteStudentPanel({
    super.key,
    required this.query,
    this.onStudentChanged,
  });

  @override
  State<CoteStudentPanel> createState() => _CoteStudentPanelState();
}

class _CoteStudentPanelState extends State<CoteStudentPanel> {
  late final _search = TextEditingController(text: widget.query.text);

  CoteStudentQuery get _query => widget.query;
  CoteStudentFilter get _filter => _query.filter;

  @override
  void initState() {
    super.initState();
    _query.addListener(_onQueryChanged);
  }

  @override
  void didUpdateWidget(covariant CoteStudentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query == widget.query) return;
    oldWidget.query.removeListener(_onQueryChanged);
    widget.query.addListener(_onQueryChanged);
    _onQueryChanged();
  }

  @override
  void dispose() {
    _query.removeListener(_onQueryChanged);
    _search.dispose();
    super.dispose();
  }

  /// Une recherche changée d'ailleurs (adresse, autre classe) : le champ suit.
  void _onQueryChanged() {
    if (_search.text != _query.text) _search.text = _query.text;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: AppDimensions.coteListPanelWidth,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: AppRadius.brLg,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.shadowCard,
      ),
      child: BlocBuilder<CoteSaisieBloc, CoteSaisieState>(
        buildWhen: (previous, current) =>
            current is CoteSaisieReady &&
            (previous is! CoteSaisieReady ||
                previous.calcs != current.calcs ||
                previous.eleves != current.eleves),
        builder: (context, state) {
          if (state is! CoteSaisieReady) return const SizedBox.shrink();
          return _content(l10n, state);
        },
      ),
    );
  }

  Widget _content(AppLocalizations l10n, CoteSaisieReady state) {
    final done = state.eleves
        .where((e) => state.calcs[e.studentId]?.complete ?? false)
        .length;
    final visible = [
      for (final eleve in state.eleves)
        if (coteStudentMatches(
          eleve: eleve,
          calc: state.calcs[eleve.studentId],
          query: _search.text,
          filter: _filter,
        ))
          eleve,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SearchFocusShortcut(
                child: ClearOnEscape(
                  controller: _search,
                  onCleared: (value) => _query.text = value,
                  child: EteeloTextInput(
                    controller: _search,
                    label: l10n.coteListSearchHint,
                    hideLabel: true,
                    placeholder: l10n.coteListSearchHint,
                    capitalization: EteeloTextCapitalization.none,
                    prefix: const Icon(
                      Icons.search_rounded,
                      size: AppDimensions.coteSearchIconSize,
                    ),
                    onChanged: (value) => _query.text = value,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SegmentedTabFilter<CoteStudentFilter>(
                selected: _filter,
                onSelected: (value) => _query.filter = value,
                semanticsLabel: l10n.coteListFilterSemantics,
                wrap: true,
                options: [
                  SegmentedTabOption(
                    label: '${l10n.coteListFilterAll} ${state.eleves.length}',
                    value: CoteStudentFilter.all,
                  ),
                  SegmentedTabOption(
                    label:
                        '${l10n.coteListFilterTodo} '
                        '${state.eleves.length - done}',
                    value: CoteStudentFilter.todo,
                  ),
                  SegmentedTabOption(
                    label: '${l10n.coteListFilterDone} $done',
                    value: CoteStudentFilter.done,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (visible.isEmpty)
          _empty(l10n)
        else
          ConstrainedBox(
            constraints: const BoxConstraints(
              maxHeight: AppDimensions.coteListPanelMaxHeight,
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: visible.length,
              itemBuilder: (context, index) => CoteStudentTile(
                key: ValueKey(visible[index].studentId),
                eleve: visible[index],
                onSelected: widget.onStudentChanged,
              ),
            ),
          ),
      ],
    );
  }

  Widget _empty(AppLocalizations l10n) {
    final query = _search.text.trim();
    final message = query.isNotEmpty
        ? l10n.coteListEmptySearch(query)
        : _filter == CoteStudentFilter.done
        ? l10n.coteListEmptyDone
        : l10n.coteListEmptyTodo;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          EteeloButton.ghost(
            label: l10n.coteListShowAll,
            fullWidth: false,
            onPressed: _query.reset,
          ),
        ],
      ),
    );
  }
}
