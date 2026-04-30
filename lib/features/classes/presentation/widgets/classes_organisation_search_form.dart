import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationSearchForm extends StatefulWidget {
  final List<ClassesOrganisationLevelOption> options;
  final bool isSearching;
  final bool isDistributing;
  final ValueChanged<ClassesOrganisationSearchRequest> onSearch;
  final void Function(
    ClassroomDistributionCriterion criterion,
    ClassesOrganisationLevelOption level,
  )
  onDistributionRequested;

  const ClassesOrganisationSearchForm({
    super.key,
    required this.options,
    required this.isSearching,
    required this.isDistributing,
    required this.onSearch,
    required this.onDistributionRequested,
  });

  @override
  State<ClassesOrganisationSearchForm> createState() =>
      _ClassesOrganisationSearchFormState();
}

class _ClassesOrganisationSearchFormState
    extends State<ClassesOrganisationSearchForm> {
  String? _selectedLevelKey;
  ClassroomDistributionCriterion _criterion =
      ClassroomDistributionCriterion.gender;

  @override
  void didUpdateWidget(covariant ClassesOrganisationSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Invalider la sélection seulement si les options ont réellement changé
    // et ne contiennent plus la clé choisie (ex : patch bootstrap post-distribution).
    // Le setState est différé en post-frame pour éviter d'appeler setState
    // pendant la phase de build/update du widget parent.
    if (oldWidget.options != widget.options &&
        _selectedLevelKey != null &&
        _selectedLevel == null) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _selectedLevelKey = null);
      });
    }
  }

  ClassesOrganisationLevelOption? get _selectedLevel {
    for (final option in widget.options) {
      if (option.key == _selectedLevelKey) return option;
    }
    return null;
  }

  bool get _hasLevel => _selectedLevel != null;

  bool get _canSearch => !widget.isSearching && _hasLevel;

  bool get _canDistribute {
    final split = _selectedLevel?.splitIntoClassrooms ?? false;
    return !widget.isDistributing && _hasLevel && !split;
  }

  void _submitSearch() {
    if (!_canSearch) return;
    widget.onSearch(
      ClassesOrganisationSearchRequest(
        firstName: '',
        lastName: '',
        surname: '',
        selectedLevel: _selectedLevel,
      ),
    );
  }

  void _onLevelChanged(String? value) {
    setState(() => _selectedLevelKey = value);
    // La recherche est déclenchée uniquement via le bouton "Rechercher".
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.classesSectionSurface,
        borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: AppColors.financeDetailShadow,
            blurRadius: AppDimensions.classesOrganisationShadowBlur,
            offset: Offset(0, AppDimensions.classesOrganisationShadowOffsetY),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.classesOrganisationSearchTitle,
            style: AppTextStyles.sectionTitle.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.classesOrganisationSearchHint,
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Row(
            children: [
              Expanded(child: _buildLevelField(l10n)),
              const SizedBox(width: AppDimensions.spacingS),
              _buildSearchButton(l10n),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingM),
          _DistributionSection(
            criterion: _criterion,
            enabled: _canDistribute,
            isLoading: widget.isDistributing,
            onCriterionChanged: (value) => setState(() => _criterion = value),
            onPressed: () {
              final level = _selectedLevel;
              if (level == null) return;
              widget.onDistributionRequested(_criterion, level);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLevelField(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedLevelKey,
      isExpanded: true,
      style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
      decoration: _fieldDecoration(
        label: '${l10n.targetCycleLabel} / ${l10n.targetLevelLabel}',
        icon: Icons.school_outlined,
      ),
      items: widget.options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.key,
              child: Text(
                option.label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
              ),
            ),
          )
          .toList(growable: false),
      onChanged: widget.options.isEmpty ? null : _onLevelChanged,
    );
  }

  Widget _buildSearchButton(AppLocalizations l10n) {
    return Tooltip(
      message: l10n.search,
      child: ElevatedButton.icon(
        onPressed: _canSearch ? _submitSearch : null,
        icon: widget.isSearching
            ? const SizedBox(
                width: AppDimensions.detailMiniIconSize,
                height: AppDimensions.detailMiniIconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.surface,
                ),
              )
            : const Icon(Icons.search),
        label: Text(l10n.search),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.indigo,
          foregroundColor: AppColors.surface,
          disabledBackgroundColor: AppColors.classesDisabledBg,
          disabledForegroundColor: AppColors.classesDisabledFg,
          minimumSize: const Size(
            132,
            AppDimensions.minTouchTarget,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.spacingS),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacingM,
            vertical: AppDimensions.spacingS,
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.background,
      floatingLabelStyle: const TextStyle(color: AppColors.classesFocusRing),
      prefixIcon: Icon(icon, color: AppColors.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimensions.spacingS),
        borderSide: const BorderSide(color: AppColors.classesFocusRing, width: 1.6),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: AppDimensions.spacingM,
      ),
    );
  }
}

class _DistributionSection extends StatelessWidget {
  final ClassroomDistributionCriterion criterion;
  final bool enabled;
  final bool isLoading;
  final ValueChanged<ClassroomDistributionCriterion> onCriterionChanged;
  final VoidCallback onPressed;

  const _DistributionSection({
    required this.criterion,
    required this.enabled,
    required this.isLoading,
    required this.onCriterionChanged,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.spacingM),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacingXS),
                decoration: BoxDecoration(
                  color: AppColors.financeDetailAccentSoft,
                  borderRadius: BorderRadius.circular(AppDimensions.spacingS),
                ),
                child: const Icon(
                  Icons.auto_graph_outlined,
                  size: AppDimensions.detailMiniIconSize,
                  color: AppColors.financeDetailAccent,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              Expanded(
                child: Text(
                  l10n.classesOrganisationDistributionLabel,
                  style: AppTextStyles.bodyStrong.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<ClassroomDistributionCriterion>(
                  initialValue: criterion,
                  decoration: InputDecoration(
                    labelText: l10n.classesOrganisationDistributionLabel,
                  ),
                  items: [
                    DropdownMenuItem<ClassroomDistributionCriterion>(
                      value: ClassroomDistributionCriterion.gender,
                      child: Text(l10n.classesOrganisationDistributionByGender),
                    ),
                    DropdownMenuItem<ClassroomDistributionCriterion>(
                      value: ClassroomDistributionCriterion.percentage,
                      child: Text(l10n.classesOrganisationDistributionByPercentage),
                    ),
                  ],
                  onChanged: enabled
                      ? (value) {
                          if (value != null) onCriterionChanged(value);
                        }
                      : null,
                ),
              ),
              const SizedBox(width: AppDimensions.spacingS),
              ElevatedButton.icon(
                onPressed: enabled ? onPressed : null,
                icon: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  child: isLoading
                      ? const SizedBox(
                          key: ValueKey('distribution-loading'),
                          width: AppDimensions.detailMiniIconSize,
                          height: AppDimensions.detailMiniIconSize,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.surface,
                          ),
                        )
                      : const Icon(
                          Icons.auto_graph_outlined,
                          key: ValueKey('distribution-idle'),
                        ),
                ),
                label: Text(l10n.classesOrganisationDistributionAction),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.indigo,
                  foregroundColor: AppColors.surface,
                  disabledBackgroundColor: AppColors.classesDisabledBg,
                  disabledForegroundColor: AppColors.classesDisabledFg,
                  minimumSize: const Size(
                    150,
                    AppDimensions.minTouchTarget,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}