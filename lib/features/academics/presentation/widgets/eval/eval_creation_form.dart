import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_radius.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/eteelo_button.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_select_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/chapitre_option.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/sous_periode_notation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/statut_periode.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_labels.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/cours_notation_view_model.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_type_cards.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_write_gate.dart';

/// Formulaire de création d'une évaluation (spec §2–§5). Gère l'état local du
/// formulaire, applique les défauts du type, câble la cascade période →
/// sous-période, valide, et soumet via [CreateEvaluationBloc]. Ferme la modale en
/// résolvant l'`Evaluation` créée au succès.
class EvalCreationForm extends StatefulWidget {
  final CoursNotationDetail detail;
  final String classroomName;

  const EvalCreationForm({
    super.key,
    required this.detail,
    required this.classroomName,
  });

  @override
  State<EvalCreationForm> createState() => _EvalCreationFormState();
}

class _EvalCreationFormState extends State<EvalCreationForm> {
  TypeEvaluation _type = TypeEvaluation.interro;
  String? _periodeId;
  String? _sousPeriodeId;
  DateTime? _date;
  Set<String> _chapitreIds = const {};
  late final TextEditingController _maxController;
  late final TextEditingController _poidsController;

  List<PeriodeNotation> get _periodes => widget.detail.periodes;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    if (_periodes.isNotEmpty) {
      // Défaut : la première période encore OUVERTE (repli sur la première si
      // toutes clôturées), pour ne pas ouvrir le formulaire sur une cible
      // verrouillée quand un choix valide existe.
      final periode = _periodes.firstWhere(
        (p) => p.statut != StatutPeriode.cloturee,
        orElse: () => _periodes.first,
      );
      _periodeId = periode.periodeScolaireId;
      _sousPeriodeId = _defaultSousPeriodeId(periode);
    }
    final defaults = evalTypeDefaults(_type);
    _maxController = TextEditingController(text: _fmt(defaults.max));
    _poidsController = TextEditingController(text: '${defaults.poids}');
  }

  @override
  void dispose() {
    _maxController.dispose();
    _poidsController.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  PeriodeNotation? get _selectedPeriode {
    for (final p in _periodes) {
      if (p.periodeScolaireId == _periodeId) return p;
    }
    return null;
  }

  SousPeriodeNotation? get _selectedSousPeriode {
    final sps = _selectedPeriode?.sousPeriodes ?? const <SousPeriodeNotation>[];
    for (final sp in sps) {
      if (sp.sousPeriodeId == _sousPeriodeId) return sp;
    }
    return null;
  }

  /// Id de la première sous-période OUVERTE de [periode] (repli sur la première ;
  /// `null` si aucune).
  String? _defaultSousPeriodeId(PeriodeNotation periode) {
    final sps = periode.sousPeriodes;
    if (sps.isEmpty) return null;
    final sp = sps.firstWhere(
      (s) => s.statut != StatutPeriode.cloturee,
      orElse: () => sps.first,
    );
    return sp.sousPeriodeId;
  }

  bool get _isExamen => _type == TypeEvaluation.examen;

  bool get _isPeriodeClosed =>
      _selectedPeriode?.statut == StatutPeriode.cloturee;

  bool get _isSousPeriodeClosed =>
      _selectedSousPeriode?.statut == StatutPeriode.cloturee;

  /// Cible verrouillée : on n'ajoute pas d'évaluation à une période clôturée.
  /// Examen → la période scolaire ; journalière → la sous-période (ou son
  /// parent clôturé, par sécurité).
  bool get _isTargetClosed =>
      _isExamen ? _isPeriodeClosed : _isPeriodeClosed || _isSousPeriodeClosed;

  /// Plafond EXAMEN de la période (`maxExamenParPeriodeScolaire`, bundle) —
  /// un seul créneau examen par période dans le modèle actuel (`PeriodeNotation.
  /// examen`), donc « atteint » dès qu'un examen existe. Plafond `null` (bundle
  /// pas encore pullé) → pas de blocage local, le backstop serveur reste le
  /// dernier rempart.
  bool get _examenPlafondReached {
    final maxExamen = widget.detail.plafonds?.maxExamenParPeriodeScolaire;
    if (maxExamen == null) return false;
    final existing = _selectedPeriode?.examen != null ? 1 : 0;
    return existing >= maxExamen;
  }

  /// Plafond journalier (`maxJournalierParSousPeriode`, bundle) — nombre
  /// d'évaluations (tous types journaliers confondus) déjà présentes dans la
  /// sous-période sélectionnée, pour la date choisie.
  bool get _journalierPlafondReached {
    final maxJournalier = widget.detail.plafonds?.maxJournalierParSousPeriode;
    final date = _date;
    final sp = _selectedSousPeriode;
    if (maxJournalier == null || date == null || sp == null) return false;
    final day = DateTime.utc(date.year, date.month, date.day);
    var count = 0;
    for (final groupe in sp.evaluationsParType) {
      for (final ev in groupe.evaluations) {
        final evDay = DateTime.utc(ev.date.year, ev.date.month, ev.date.day);
        if (evDay == day) count++;
      }
    }
    return count >= maxJournalier;
  }

  bool get _isPlafondReached =>
      _isExamen ? _examenPlafondReached : _journalierPlafondReached;

  double get _maxValue =>
      double.tryParse(_maxController.text.trim().replaceAll(',', '.')) ?? 0;

  int get _poidsValue => int.tryParse(_poidsController.text.trim()) ?? 0;

  bool get _isValid {
    if (_date == null || _maxValue <= 0 || _poidsValue <= 0) return false;
    if (_isExamen) return _periodeId != null && _periodeId!.isNotEmpty;
    return _sousPeriodeId != null && _sousPeriodeId!.isNotEmpty;
  }

  void _onTypeChanged(TypeEvaluation type) {
    final defaults = evalTypeDefaults(type);
    setState(() {
      _type = type;
      _maxController.text = _fmt(defaults.max);
      _poidsController.text = '${defaults.poids}';
    });
  }

  void _onPeriodeChanged(String? id) {
    if (id == null) return;
    setState(() {
      _periodeId = id;
      final periode = _selectedPeriode;
      final sps = periode?.sousPeriodes ?? const <SousPeriodeNotation>[];
      final stillThere = sps.any((sp) => sp.sousPeriodeId == _sousPeriodeId);
      if (!stillThere) {
        _sousPeriodeId = periode == null
            ? null
            : _defaultSousPeriodeId(periode);
      }
    });
  }

  /// Type EXAMEN grisé si la branche n'a pas d'examen (`maxExamenParPeriodeScolaire`
  /// `null`, bundle) — jamais traité comme 0 ; plafonds pas encore en cache
  /// (`null`) → pas de grisage (le backstop serveur reste le dernier rempart).
  Set<TypeEvaluation> get _disabledTypes {
    final plafonds = widget.detail.plafonds;
    if (plafonds == null || plafonds.maxExamenParPeriodeScolaire != null) {
      return const {};
    }
    return const {TypeEvaluation.examen};
  }

  void _submit() {
    // Garde métier : jamais d'évaluation sur une période clôturée, un
    // plafond atteint, ou un type grisé (ex. EXAMEN devenu indisponible si le
    // bundle se rafraîchit pendant que la modale est ouverte) — le bouton est
    // déjà désactivé en pratique, ceci couvre les chemins programmatiques.
    if (_isTargetClosed ||
        _isPlafondReached ||
        _disabledTypes.contains(_type)) {
      return;
    }
    final request = _isExamen
        ? CreateEvaluationRequest.examen(
            date: _date!,
            maxPoints: _maxValue,
            periodeScolaireId: _periodeId!,
            poids: _poidsValue,
            chapitreIds: _chapitreIds.toList(growable: false),
          )
        : CreateEvaluationRequest.journaliere(
            type: _type,
            date: _date!,
            maxPoints: _maxValue,
            sousPeriodeId: _sousPeriodeId!,
            poids: _poidsValue,
            chapitreIds: _chapitreIds.toList(growable: false),
          );
    context.read<CreateEvaluationBloc>().add(
      CreateEvaluationSubmitted(
        coursId: widget.detail.coursId,
        request: request,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocConsumer<CreateEvaluationBloc, CreateEvaluationState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      buildWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == CreateEvaluationStatus.success) {
          Navigator.of(context).pop(state.createdEvaluation);
        } else if (state.status == CreateEvaluationStatus.failure) {
          AppSnackBar.showError(context, l10n.evalCreateErrorToast);
        }
      },
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EvalTypeCards(
              selected: _type,
              onChanged: _onTypeChanged,
              disabledTypes: _disabledTypes,
            ),
            const SizedBox(height: AppSpacing.lg),
            _cascade(l10n),
            if (!_isTargetClosed && _isPlafondReached) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.evalCreateMaxReachedError,
                style: AppTypography.bodySmall.copyWith(color: AppColors.error),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            EteeloDateInput(
              label: l10n.evalCreateFieldDate,
              placeholder: l10n.evalCreateFieldDateHint,
              value: _date,
              required: true,
              firstDate: DateTime(2020),
              lastDate: DateTime(DateTime.now().year + 1, 12, 31),
              onChanged: (d) => setState(() => _date = d),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: EteeloTextInput(
                    label: l10n.evalCreateFieldMax,
                    controller: _maxController,
                    required: true,
                    keyboardType: EteeloTextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: EteeloTextInput(
                    label: l10n.evalCreateFieldPoids,
                    controller: _poidsController,
                    required: true,
                    keyboardType: EteeloTextInputType.number,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ChaptersField(
              options: widget.detail.chapitresDisponibles,
              selectedIds: _chapitreIds,
              onChanged: (ids) => setState(() => _chapitreIds = ids),
            ),
            const SizedBox(height: AppSpacing.lg),
            _hint(l10n),
            const SizedBox(height: AppSpacing.md),
            _actions(l10n, state),
          ],
        );
      },
    );
  }

  Widget _cascade(AppLocalizations l10n) {
    // Découpage dérivé du nombre de périodes (mêmes libellés que la page détail).
    final decoupage = periodeDecoupageFromCount(_periodes.length);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: EteeloSelectInput<String>(
            label: decoupageFieldLabel(l10n, decoupage),
            value: _periodeId,
            onChanged: _onPeriodeChanged,
            errorText: _isPeriodeClosed
                ? l10n.evalCreateClosedPeriodError
                : null,
            items: [
              for (final p in _periodes)
                EteeloSelectItem<String>(
                  value: p.periodeScolaireId,
                  label: periodeScolaireLabel(l10n, p.ordre, decoupage),
                  // Verrou de clôture (bundle, DF-M) : une période CLOTUREE ne
                  // peut plus recevoir de saisie — grisée, pas seulement
                  // bloquée après coup par errorText/submit.
                  enabled: p.statut != StatutPeriode.cloturee,
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: EteeloSelectInput<String>(
            label: l10n.evalCreateFieldSousPeriode,
            value: _isExamen ? null : _sousPeriodeId,
            enabled: !_isExamen,
            placeholder: _isExamen ? l10n.evalCreateExamPlaceholder : null,
            // Erreur affichée ici seulement si le blocage vient de la
            // sous-période (sinon il est déjà signalé sur la période scolaire).
            errorText: (!_isExamen && !_isPeriodeClosed && _isSousPeriodeClosed)
                ? l10n.evalCreateClosedPeriodError
                : null,
            onChanged: (id) => setState(() => _sousPeriodeId = id),
            items: [
              for (final sp in _selectedPeriode?.sousPeriodes ?? const [])
                EteeloSelectItem<String>(
                  value: sp.sousPeriodeId,
                  label: l10n.courseDetailPeriodLabel(sp.ordre),
                  // Verrou de clôture (bundle, DF-M) : idem période, une
                  // sous-période CLOTUREE est grisée dans le picker.
                  enabled: sp.statut != StatutPeriode.cloturee,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _hint(AppLocalizations l10n) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(
            Icons.info_outline_rounded,
            size: 15,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            l10n.evalCreateHint(widget.detail.effectif, widget.classroomName),
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _actions(AppLocalizations l10n, CreateEvaluationState state) {
    return Row(
      children: [
        Expanded(
          child: EteeloButton.secondary(
            label: l10n.evalCreateCancel,
            size: EteeloButtonSize.regular,
            onPressed: state.isInProgress
                ? null
                : () => Navigator.of(context).pop(),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          // Gel READ_ONLY (ADR-010) : la modale peut être ouverte au moment où
          // le tick de fraîcheur bascule le mode — le submit doit être gaté
          // comme le FAB d'entrée.
          child: SessionWriteGate(
            child: EteeloButton.primary(
              label: l10n.evalCreateSubmit,
              icon: Icons.check_rounded,
              isLoading: state.isInProgress,
              size: EteeloButtonSize.regular,
              onPressed:
                  (_isValid &&
                      !_isTargetClosed &&
                      !_isPlafondReached &&
                      !_disabledTypes.contains(_type) &&
                      !state.isInProgress)
                  ? _submit
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Champ « Chapitres concernés » : checklist des chapitres du cours (bundle
/// `grades-referential`, cochables, couverture intra-agrégat de l'évaluation).
/// Vide (bundle pas encore pullé / cours sans chapitre) → message muet, jamais
/// un champ vide silencieux.
class _ChaptersField extends StatelessWidget {
  final List<ChapitreOption> options;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;

  const _ChaptersField({
    required this.options,
    required this.selectedIds,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.evalCreateFieldChapitres,
          style: AppTypography.labelFormMedium.copyWith(
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        if (options.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: AppRadius.brSm,
              border: Border.all(color: AppColors.borderStrong),
            ),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                const Icon(
                  Icons.menu_book_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.evalCreateChapitresEmpty,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(option.titre),
                  selected: selectedIds.contains(option.id),
                  onSelected: (checked) {
                    final next = {...selectedIds};
                    if (checked) {
                      next.add(option.id);
                    } else {
                      next.remove(option.id);
                    }
                    onChanged(next);
                  },
                ),
            ],
          ),
      ],
    );
  }
}
