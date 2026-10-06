import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/theme/tokens/app_colors.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/theme/tokens/app_typography.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/core/widgets/eteelo_date_input.dart';
import 'package:school_app_flutter/core/widgets/eteelo_text_input.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/cours_notation_detail.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/create_evaluation_request.dart';
import 'package:school_app_flutter/features/academics/domain/entities/notation/type_evaluation.dart';
import 'package:school_app_flutter/features/academics/domain/entities/sujet/evaluation_cadre.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_bloc.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_event.dart';
import 'package:school_app_flutter/features/academics/presentation/bloc/create_evaluation_state.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_creation_rules.dart';
import 'package:school_app_flutter/features/academics/presentation/helpers/eval_title.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_chapters_field.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_creation_cascade.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_creation_footer.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/eval/eval_type_cards.dart';
import 'package:school_app_flutter/features/academics/presentation/widgets/sujet/sujet_cadre_fields.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// Formulaire de création d'une évaluation (spec §2–§5). Tient l'état local
/// du formulaire, applique les défauts du type, calcule le titre et soumet via
/// [CreateEvaluationBloc]. Ferme la modale en résolvant l'`Evaluation` créée
/// au succès. Les règles de la cible vivent dans [EvalCreationRules].
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
  int? _dureeMinutes;
  List<String> _programme = const [];
  late final TextEditingController _maxController;
  late final TextEditingController _poidsController;
  final TextEditingController _consignesController = TextEditingController();

  EvalCreationRules get _rules => EvalCreationRules(
    detail: widget.detail,
    type: _type,
    periodeId: _periodeId,
    sousPeriodeId: _sousPeriodeId,
    date: _date,
  );

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    final periode = EvalCreationRules.defaultPeriode(widget.detail.periodes);
    if (periode != null) {
      _periodeId = periode.periodeScolaireId;
      _sousPeriodeId = EvalCreationRules.defaultSousPeriodeId(periode);
    }
    final defaults = evalTypeDefaults(_type);
    _maxController = TextEditingController(text: _fmt(defaults.max));
    _poidsController = TextEditingController(text: '${defaults.poids}');
    _dureeMinutes = defaults.dureeMinutes;
  }

  @override
  void dispose() {
    _maxController.dispose();
    _poidsController.dispose();
    _consignesController.dispose();
    super.dispose();
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();

  double get _maxValue =>
      double.tryParse(_maxController.text.trim().replaceAll(',', '.')) ?? 0;

  int get _poidsValue => int.tryParse(_poidsController.text.trim()) ?? 0;

  bool get _isValid =>
      _date != null && _maxValue > 0 && _poidsValue > 0 && _rules.hasTarget;

  List<String> get _selectedChapitreTitres => [
    for (final option in widget.detail.chapitresDisponibles)
      if (_chapitreIds.contains(option.id)) option.titre,
  ];

  void _onTypeChanged(TypeEvaluation type) {
    final defaults = evalTypeDefaults(type);
    setState(() {
      _type = type;
      _maxController.text = _fmt(defaults.max);
      _poidsController.text = '${defaults.poids}';
      _dureeMinutes = defaults.dureeMinutes;
    });
  }

  void _onPeriodeChanged(String? id) {
    if (id == null) return;
    setState(() {
      _periodeId = id;
      final periode = _rules.periode;
      final stillThere = (periode?.sousPeriodes ?? const []).any(
        (sp) => sp.sousPeriodeId == _sousPeriodeId,
      );
      if (!stillThere) {
        _sousPeriodeId = periode == null
            ? null
            : EvalCreationRules.defaultSousPeriodeId(periode);
      }
    });
  }

  void _submit() {
    final rules = _rules;
    // Garde métier : le bouton est déjà désactivé en pratique, ceci couvre les
    // chemins programmatiques (bundle rafraîchi pendant que la modale est
    // ouverte).
    if (!_isValid || !rules.isTargetOpen) return;
    final l10n = AppLocalizations.of(context)!;
    final titre = buildEvalTitle(
      l10n,
      type: _type,
      periode: rules.periode,
      sousPeriodeId: _sousPeriodeId,
      periodeCount: rules.periodes.length,
      chapitreTitres: _selectedChapitreTitres,
    );
    final cadre = EvaluationCadre(
      dureeMinutes: _dureeMinutes,
      programme: _programme,
      consignes: _consignesController.text,
    ).normalized();
    final chapitreIds = _chapitreIds.toList(growable: false);
    final request = rules.isExamen
        ? CreateEvaluationRequest.examen(
            date: _date!,
            maxPoints: _maxValue,
            periodeScolaireId: _periodeId!,
            poids: _poidsValue,
            chapitreIds: chapitreIds,
            titre: titre,
            cadre: cadre,
          )
        : CreateEvaluationRequest.journaliere(
            type: _type,
            date: _date!,
            maxPoints: _maxValue,
            sousPeriodeId: _sousPeriodeId!,
            poids: _poidsValue,
            chapitreIds: chapitreIds,
            titre: titre,
            cadre: cadre,
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
        final rules = _rules;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EvalTypeCards(
              selected: _type,
              onChanged: _onTypeChanged,
              disabledTypes: rules.disabledTypes,
            ),
            const SizedBox(height: AppSpacing.lg),
            EvalCreationCascade(
              rules: rules,
              onPeriodeChanged: _onPeriodeChanged,
              onSousPeriodeChanged: (id) => setState(() => _sousPeriodeId = id),
            ),
            if (!rules.isTargetClosed && rules.isPlafondReached) ...[
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
            _maxAndPoids(l10n),
            const SizedBox(height: AppSpacing.md),
            EvalChaptersField(
              options: widget.detail.chapitresDisponibles,
              selectedIds: _chapitreIds,
              onChanged: (ids) => setState(() => _chapitreIds = ids),
            ),
            const SizedBox(height: AppSpacing.lg),
            SujetCadreFields(
              dureeMinutes: _dureeMinutes,
              onDureeChanged: (m) => setState(() => _dureeMinutes = m),
              programme: _programme,
              onProgrammeChanged: (lines) => setState(() => _programme = lines),
              onReprendreChapitres: _chapitreIds.isEmpty
                  ? null
                  : () => setState(() => _programme = _selectedChapitreTitres),
              consignes: _consignesController,
            ),
            const SizedBox(height: AppSpacing.sm),
            EvalCreationHint(l10n.evalCreateSujetHint),
            const SizedBox(height: AppSpacing.lg),
            EvalCreationHint(
              l10n.evalCreateHint(widget.detail.effectif, widget.classroomName),
            ),
            const SizedBox(height: AppSpacing.md),
            EvalCreationActions(
              inProgress: state.isInProgress,
              onSubmit: _isValid && rules.isTargetOpen ? _submit : null,
            ),
          ],
        );
      },
    );
  }

  Widget _maxAndPoids(AppLocalizations l10n) => Row(
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
  );
}
