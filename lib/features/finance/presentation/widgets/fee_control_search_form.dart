import 'package:flutter/material.dart';
import 'package:school_app_flutter/core/components/search/search_form_actions.dart';
import 'package:school_app_flutter/core/components/search/search_models.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/widgets/bi_tone_section_card.dart';
import 'package:school_app_flutter/features/classes/domain/entities/offline/offline_classroom.dart';
import 'package:school_app_flutter/features/finance/offline/domain/entities/local_finance_entities.dart';
import 'package:school_app_flutter/features/finance/presentation/contracts/fee_control_contracts.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/fee_control_form_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Formulaire de recherche du Contrôle des frais.
///
/// Il **n'enveloppe pas** `BiModeSearchForm` : celui-ci arme la recherche sur un
/// « OU » (les trois noms **ou** un niveau), alors qu'ici la classe et le frais
/// sont obligatoires — un frais n'existe que rapporté à un niveau. Y faire
/// entrer un troisième mode dénaturerait un composant que la Facturation, les
/// Documents, la Ré- et la Pré-inscription partagent tous les quatre. On suit
/// donc le précédent de `FirstRegistrationSearchForm` : recomposer les briques
/// de `core/components/search` sans toucher au générique.
class FeeControlSearchForm extends StatefulWidget {
  final List<SearchLevelOption> options;

  /// Grille du niveau sélectionné, fournie par le BLoC.
  final List<LocalFeeTariff> tariffs;

  /// Classes du niveau sélectionné, fournies par le BLoC.
  final List<OfflineClassroom> classrooms;

  /// Vrai pendant le chargement de la grille (sélecteur de frais grisé).
  final bool isTariffsLoading;

  /// Vrai pendant le chargement des classes (sélecteur de classe grisé).
  final bool isClassroomsLoading;

  /// Vrai quand la grille est absente de l'appareil (message distinct de
  /// « ce niveau n'a pas de frais »).
  final bool feeGridMissing;

  final bool isLoading;

  /// Émis à chaque changement de niveau pour charger la grille correspondante.
  final void Function(String schoolLevelGroupId, String schoolLevelId)
  onLevelSelected;

  final ValueChanged<FeeControlSearchRequest> onSearch;
  final VoidCallback onClear;

  const FeeControlSearchForm({
    super.key,
    required this.options,
    required this.tariffs,
    required this.classrooms,
    required this.isTariffsLoading,
    required this.isClassroomsLoading,
    required this.feeGridMissing,
    required this.isLoading,
    required this.onLevelSelected,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<FeeControlSearchForm> createState() => _FeeControlSearchFormState();
}

class _FeeControlSearchFormState extends State<FeeControlSearchForm> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _surnameController = TextEditingController();
  String? _selectedGroupId;
  String? _selectedLevelKey;
  String? _selectedClassroomId;
  String? _selectedFeeCode;
  FeeControlPaymentFilter _statusFilter = FeeControlPaymentFilter.all;

  @override
  void didUpdateWidget(covariant FeeControlSearchForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Rien de sélectionné = rien à invalider : sans ce garde, chaque rebuild du
    // parent déclencherait un setState inutile.
    final key = _selectedLevelKey;
    final levelStale =
        key != null && !widget.options.any((option) => option.key == key);
    final groupStale =
        _selectedGroupId != null &&
        !widget.options.any((o) => o.schoolLevelGroupId == _selectedGroupId);
    // La grille change avec le niveau : un frais qui n'y figure plus doit
    // disparaître, sinon le bouton resterait armé sur un code fantôme.
    final feeStale =
        _selectedFeeCode != null &&
        !widget.tariffs.any((t) => t.feeCode == _selectedFeeCode);
    // Même raison pour la classe : les classes suivent le niveau.
    final classroomStale =
        _selectedClassroomId != null &&
        !widget.classrooms.any((c) => c.id == _selectedClassroomId);

    if (levelStale || groupStale || feeStale || classroomStale) {
      setState(() {
        if (levelStale) _selectedLevelKey = null;
        if (groupStale) _selectedGroupId = null;
        if (feeStale) _selectedFeeCode = null;
        if (classroomStale) _selectedClassroomId = null;
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

  List<SearchLevelOption> get _uniqueOptions {
    final seen = <String>{};
    return widget.options
        .where((option) => seen.add(option.key))
        .toList(growable: false);
  }

  SearchLevelOption? get _selectedOption => _uniqueOptions
      .where((option) => option.key == _selectedLevelKey)
      .firstOrNull;

  LocalFeeTariff? get _selectedTariff => widget.tariffs
      .where((tariff) => tariff.feeCode == _selectedFeeCode)
      .firstOrNull;

  /// Classe ET frais : les deux sont obligatoires, les noms ne sont qu'un
  /// affinage.
  bool get _canSearch =>
      !widget.isLoading && _selectedOption != null && _selectedTariff != null;

  void _onCycleChanged(String? groupId) {
    setState(() {
      _selectedGroupId = groupId;
      _selectedLevelKey = null;
      _selectedClassroomId = null;
      _selectedFeeCode = null;
    });
  }

  void _onLevelChanged(String? levelKey) {
    setState(() {
      _selectedLevelKey = levelKey;
      _selectedClassroomId = null;
      _selectedFeeCode = null;
    });
    final option = _selectedOption;
    if (option == null) return;
    widget.onLevelSelected(option.schoolLevelGroupId, option.schoolLevelId);
  }

  /// La sentinelle « toutes les classes » revient à `null` côté critères.
  void _onClassroomChanged(String? classroomId) {
    setState(
      () => _selectedClassroomId =
          classroomId == FeeControlClassroomField.allClassroomsValue
          ? null
          : classroomId,
    );
  }

  void _onFeeChanged(String? feeCode) {
    setState(() => _selectedFeeCode = feeCode);
  }

  void _onStatusChanged(FeeControlPaymentFilter? filter) {
    if (filter == null) return;
    setState(() => _statusFilter = filter);
  }

  void _reset() {
    setState(() {
      _firstNameController.clear();
      _lastNameController.clear();
      _surnameController.clear();
      _selectedGroupId = null;
      _selectedLevelKey = null;
      _selectedClassroomId = null;
      _selectedFeeCode = null;
      _statusFilter = FeeControlPaymentFilter.all;
    });
    widget.onClear();
  }

  void _submit() {
    final option = _selectedOption;
    final tariff = _selectedTariff;
    if (!_canSearch || option == null || tariff == null) return;

    widget.onSearch(
      FeeControlSearchRequest(
        schoolLevelGroupId: option.schoolLevelGroupId,
        schoolLevelId: option.schoolLevelId,
        classroomId: _selectedClassroomId,
        feeCode: tariff.feeCode,
        statusFilter: _statusFilter,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        surname: _surnameController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final options = _uniqueOptions;
    final cycles = buildSearchCycles(options);
    final selectedGroupId =
        cycles.any((cycle) => cycle.groupId == _selectedGroupId)
        ? _selectedGroupId
        : null;
    final hasLevel = _selectedOption != null;

    final classGroup = FeeControlClassGroup(
      cycles: cycles,
      selectedGroupId: selectedGroupId,
      selectedLevelKey: hasLevel ? _selectedLevelKey : null,
      classrooms: widget.classrooms,
      selectedClassroomId: _selectedClassroomId,
      tariffs: widget.tariffs,
      selectedFeeCode: _selectedFeeCode,
      statusFilter: _statusFilter,
      hasLevel: hasLevel,
      isLoading: widget.isLoading,
      isTariffsLoading: widget.isTariffsLoading,
      isClassroomsLoading: widget.isClassroomsLoading,
      feeGridMissing: widget.feeGridMissing,
      isComplete: _canSearch,
      onCycleChanged: _onCycleChanged,
      onLevelChanged: _onLevelChanged,
      onClassroomChanged: _onClassroomChanged,
      onFeeChanged: _onFeeChanged,
      onStatusChanged: _onStatusChanged,
    );

    final studentGroup = FeeControlStudentGroup(
      firstNameController: _firstNameController,
      lastNameController: _lastNameController,
      surnameController: _surnameController,
      enabled: !widget.isLoading,
    );

    final actions = SearchFormActions(
      isLoading: widget.isLoading,
      canSearch: _canSearch,
      onClear: _reset,
      onSearch: _submit,
      clearLabel: l10n.clear,
      searchLabel: l10n.search,
    );

    return BiToneSectionCard(
      title: l10n.feeControlSearchTitle,
      subtitle: l10n.feeControlSearchHelpBanner,
      icon: Icons.fact_check_outlined,
      bodyPadding: const EdgeInsets.all(AppDimensions.spacingL - 2),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= AppBreakpoints.formMediumMin;
          final groups = isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: classGroup),
                    const SizedBox(width: AppDimensions.spacingM),
                    Expanded(child: studentGroup),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    classGroup,
                    const SizedBox(height: AppDimensions.spacingM),
                    studentGroup,
                  ],
                );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              groups,
              const SizedBox(height: AppDimensions.spacingM),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          );
        },
      ),
    );
  }
}
