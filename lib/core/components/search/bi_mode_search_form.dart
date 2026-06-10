import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:school_app_flutter/core/components/search/search_group_box.dart';
import 'package:school_app_flutter/core/components/search/search_level_cascade.dart';
import 'package:school_app_flutter/core/components/search/search_mode_badges.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/components/search/search_name_fields.dart';
import 'package:school_app_flutter/core/components/search/search_or_separator.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';

/// Libellés (i18n) de la carte de recherche bi-mode, fournis par la feature.
class BiModeSearchLabels {
  final String title;
  final String helpBanner;
  final String byStudentGroup;
  final String byClassGroup;
  final String orSeparator;
  final String activeModeLabel;
  final String studentBadge;
  final String classBadge;
  final String cycleLabel;
  final String levelLabel;
  final String levelPlaceholder;
  final String firstNameLabel;
  final String lastNameLabel;
  final String surnameLabel;
  final String searchLabel;
  final String clearLabel;

  const BiModeSearchLabels({
    required this.title,
    required this.helpBanner,
    required this.byStudentGroup,
    required this.byClassGroup,
    required this.orSeparator,
    required this.activeModeLabel,
    required this.studentBadge,
    required this.classBadge,
    required this.cycleLabel,
    required this.levelLabel,
    required this.levelPlaceholder,
    required this.firstNameLabel,
    required this.lastNameLabel,
    required this.surnameLabel,
    required this.searchLabel,
    required this.clearLabel,
  });
}

/// Carte de recherche bi-mode (par nom OU par cycle/niveau, ou les deux).
///
/// Générique (cœur design-system) : la logique « OU » et le rendu sont
/// partagés ; chaque feature fournit ses libellés, ses options et son
/// gestionnaire [onSearch]. La recherche est possible dès qu'un mode est
/// complet (les 3 noms OU un niveau choisi).
class BiModeSearchForm extends StatefulWidget {
  final List<SearchLevelOption> options;
  final bool isLoading;
  final ValueChanged<SearchRequest> onSearch;
  final BiModeSearchLabels labels;

  /// Formatters appliqués aux 3 champs de noms (ex. capitalisation auto).
  final List<TextInputFormatter>? nameInputFormatters;

  /// Pastille d'aide optionnelle affichée en tête du formulaire (texte détaillé).
  final String? helpPill;

  /// Icône de la pastille d'aide (par défaut : information).
  final IconData helpPillIcon;

  const BiModeSearchForm({
    super.key,
    required this.options,
    required this.isLoading,
    required this.onSearch,
    required this.labels,
    this.nameInputFormatters,
    this.helpPill,
    this.helpPillIcon = Icons.info_outline,
  });

  @override
  State<BiModeSearchForm> createState() => _BiModeSearchFormState();
}

class _BiModeSearchFormState extends State<BiModeSearchForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();
  String? _selectedGroupId;
  String? _selectedLevelKey;

  @override
  void didUpdateWidget(covariant BiModeSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    final key = _selectedLevelKey;
    final levelStillValid =
        key != null && widget.options.any((option) => option.key == key);
    final groupStillValid =
        _selectedGroupId != null &&
        widget.options.any((o) => o.schoolLevelGroupId == _selectedGroupId);

    if ((key != null && !levelStillValid && mounted) ||
        (_selectedGroupId != null && !groupStillValid && mounted)) {
      setState(() {
        if (!levelStillValid) _selectedLevelKey = null;
        if (!groupStillValid) _selectedGroupId = null;
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _surnameController.dispose();
    super.dispose();
  }

  bool _hasAllNames() =>
      _firstNameController.text.trim().isNotEmpty &&
      _lastNameController.text.trim().isNotEmpty &&
      _surnameController.text.trim().isNotEmpty;

  bool _hasLevel() =>
      _selectedLevelKey != null &&
      widget.options.any((option) => option.key == _selectedLevelKey);

  bool get _canSearch => !widget.isLoading && (_hasAllNames() || _hasLevel());

  List<SearchLevelOption> get _uniqueOptions {
    final seen = <String>{};
    return widget.options
        .where((option) => seen.add(option.key))
        .toList(growable: false);
  }

  void _submit() {
    if (!_canSearch) return;

    final selectedOption = _uniqueOptions
        .where((option) => option.key == _selectedLevelKey)
        .firstOrNull;

    widget.onSearch(
      SearchRequest(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        surname: _surnameController.text.trim(),
        schoolLevelGroupId: selectedOption?.schoolLevelGroupId ?? '',
        schoolLevelId: selectedOption?.schoolLevelId ?? '',
      ),
    );
  }

  void _reset() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _surnameController.clear();
      _selectedGroupId = null;
      _selectedLevelKey = null;
    });
  }

  void _onNameChanged(String _) => setState(() {});

  void _onCycleChanged(String? groupId) {
    setState(() {
      _selectedGroupId = groupId;
      _selectedLevelKey = null;
    });
  }

  void _onLevelChanged(String? levelKey) {
    setState(() => _selectedLevelKey = levelKey);
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final options = _uniqueOptions;
    final cycles = buildSearchCycles(options);
    final selectedGroupId =
        cycles.any((cycle) => cycle.groupId == _selectedGroupId)
        ? _selectedGroupId
        : null;
    final selectedLevelKey =
        options.any((option) => option.key == _selectedLevelKey)
        ? _selectedLevelKey
        : null;

    final hasNames = _hasAllNames();
    final hasLevel = _hasLevel();

    final studentGroup = SearchGroupBox(
      icon: Icons.person_outline,
      title: labels.byStudentGroup,
      isComplete: hasNames,
      child: SearchNameFields(
        firstNameController: _firstNameController,
        lastNameController: _lastNameController,
        surnameController: _surnameController,
        firstNameLabel: labels.firstNameLabel,
        lastNameLabel: labels.lastNameLabel,
        surnameLabel: labels.surnameLabel,
        enabled: !widget.isLoading,
        inputFormatters: widget.nameInputFormatters,
        onChanged: _onNameChanged,
      ),
    );

    final classGroup = SearchGroupBox(
      icon: Icons.grid_view_rounded,
      title: labels.byClassGroup,
      isComplete: hasLevel,
      child: SearchLevelCascade(
        cycles: cycles,
        selectedGroupId: selectedGroupId,
        selectedLevelKey: selectedLevelKey,
        isLoading: widget.isLoading,
        cycleLabel: labels.cycleLabel,
        levelLabel: labels.levelLabel,
        levelPlaceholder: labels.levelPlaceholder,
        onCycleChanged: _onCycleChanged,
        onLevelChanged: _onLevelChanged,
      ),
    );

    final modeBadges = SearchModeBadges(
      activeModeLabel: labels.activeModeLabel,
      studentBadgeLabel: labels.studentBadge,
      classBadgeLabel: labels.classBadge,
      studentArmed: hasNames,
      classArmed: hasLevel,
    );

    final actions = _buildActions();

    return BiToneSectionCard(
      title: labels.title,
      subtitle: labels.helpBanner,
      icon: Icons.search_rounded,
      bodyPadding: const EdgeInsets.all(AppDimensions.spacingL - 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.helpPill != null) ...[
            _HelpPill(icon: widget.helpPillIcon, text: widget.helpPill!),
            const SizedBox(height: AppDimensions.spacingM),
          ],
          LayoutBuilder(
            builder: (context, constraints) {
              // Côte à côte dès qu'il y a assez d'espace, sinon empilés.
              final isWide =
                  constraints.maxWidth >= AppBreakpoints.formMediumMin;
              if (isWide) {
                return _WideLayout(
                  studentGroup: studentGroup,
                  orSeparator: SearchOrSeparator(
                    label: labels.orSeparator,
                    vertical: false,
                  ),
                  classGroup: classGroup,
                  modeBadges: modeBadges,
                  actions: actions,
                );
              }
              return _CompactLayout(
                studentGroup: studentGroup,
                orSeparator: SearchOrSeparator(label: labels.orSeparator),
                classGroup: classGroup,
                modeBadges: modeBadges,
                actions: actions,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    // Convention app : « Effacer » à gauche, « Rechercher » (primaire) à droite.
    return Wrap(
      spacing: AppDimensions.spacingS,
      runSpacing: AppDimensions.spacingS,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.end,
      children: [
        EteeloButton.ghost(
          onPressed: widget.isLoading ? null : _reset,
          icon: Icons.refresh_rounded,
          label: widget.labels.clearLabel,
        ),
        EteeloButton.primary(
          onPressed: _canSearch ? _submit : null,
          icon: Icons.search_rounded,
          label: widget.labels.searchLabel,
          isLoading: widget.isLoading,
        ),
      ],
    );
  }
}

/// Disposition large : les deux groupes côte à côte, séparés par « OU ».
class _WideLayout extends StatelessWidget {
  final Widget studentGroup;
  final Widget orSeparator;
  final Widget classGroup;
  final Widget modeBadges;
  final Widget actions;

  const _WideLayout({
    required this.studentGroup,
    required this.orSeparator,
    required this.classGroup,
    required this.modeBadges,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pas d'IntrinsicHeight : les groupes contiennent un LayoutBuilder
        // (champs nom), incompatible avec le calcul des dimensions intrinsèques.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 3, child: studentGroup),
            orSeparator,
            Expanded(flex: 2, child: classGroup),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: modeBadges),
            const SizedBox(width: AppDimensions.spacingM),
            actions,
          ],
        ),
      ],
    );
  }
}

/// Pastille d'aide en tête de formulaire : icône + texte explicatif détaillé.
class _HelpPill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HelpPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.bleuArdoise.withValues(alpha: 0.06),
        borderRadius: AppRadius.brMd,
        border: Border.all(color: AppColors.bleuArdoise.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.bleuArdoise),
          const SizedBox(width: AppDimensions.spacingS),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Disposition compacte : groupes empilés + « OU » + badges + actions.
class _CompactLayout extends StatelessWidget {
  final Widget studentGroup;
  final Widget orSeparator;
  final Widget classGroup;
  final Widget modeBadges;
  final Widget actions;

  const _CompactLayout({
    required this.studentGroup,
    required this.orSeparator,
    required this.classGroup,
    required this.modeBadges,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        studentGroup,
        orSeparator,
        classGroup,
        const SizedBox(height: AppDimensions.spacingM),
        modeBadges,
        const SizedBox(height: AppDimensions.spacingM),
        Align(alignment: Alignment.centerRight, child: actions),
      ],
    );
  }
}
