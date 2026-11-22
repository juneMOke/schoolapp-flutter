import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/school_level_group_bundle.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_question.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/fee_control_classroom_select.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/fee_control_situation_card.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/recouvrement_fee_picker_field.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/recouvrement_perimeter_bar.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// La question du contrôle des frais : la barre « Quels frais analyser ? » et
/// sa classe, puis la carte « Situation recherchée ».
///
/// **Aucun bouton « Rechercher »** (maquette `RecControleTab`) : changer de
/// frais ou de classe relance la lecture (I1), un segment filtre ce qui est
/// déjà lu (I2), le montant filtre à chaque chiffre (I3). La question vit ici,
/// s'écrit dans l'adresse et devient la dernière visite.
class FeeControlPerimeter extends StatefulWidget {
  final String academicYearId;
  final List<SchoolLevelGroupBundle> groups;

  /// Question imposée (tests, liens) ; à défaut l'adresse, puis la dernière
  /// visite.
  final FeeControlQuestion? initial;

  const FeeControlPerimeter({
    super.key,
    required this.academicYearId,
    required this.groups,
    this.initial,
  });

  @override
  State<FeeControlPerimeter> createState() => _FeeControlPerimeterState();
}

class _FeeControlPerimeterState extends State<FeeControlPerimeter> {
  final _threshold = TextEditingController();
  FeeControlQuestion _question = const FeeControlQuestion();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final lastVisit = FeeControlQuestion.lastVisit;
    final arrived =
        widget.initial ??
        FeeControlQuestion.fromLocation(context) ??
        lastVisit ??
        const FeeControlQuestion();
    // R12 : venu du tableau de bord sur un périmètre établissement ou cycle,
    // l'adresse porte les frais mais pas la classe — celle de la dernière
    // visite est reprise ; sans elle, la carte d'invitation.
    _question = arrived.classroomId == null
        ? arrived.copyWith(classroomId: lastVisit?.classroomId)
        : arrived;
    final amount = _question.thresholdInCents;
    if (amount != null) _threshold.text = '${amount ~/ 100}';
    context.read<FeeControlBloc>().add(
      FeeControlCatalogRequested(academicYearId: widget.academicYearId),
    );
  }

  @override
  void dispose() {
    _threshold.dispose();
    super.dispose();
  }

  /// Le catalogue arrivé : la question se complète (premier frais, frais
  /// inconnus écartés, classe disparue oubliée), puis la lecture part.
  void _onCatalog(FeeControlState state) {
    if (state.catalogStatus != EnrollmentLoadStatus.success) return;
    final titles = context.read<FeeSectionTitlesCubit>().state;
    final known = {for (final n in state.natures) n.feeCode};
    var fees = [
      for (final code in recouvrementSchoolOrder(_question.feeCodes, titles))
        if (known.contains(code)) code,
    ];
    if (fees.isEmpty && state.natures.isNotEmpty) {
      fees = [state.natures.first.feeCode];
    }
    final room = _question.classroomId;
    final roomKnown =
        room == null ||
        room == feeControlUnassigned ||
        state.classrooms.any((c) => c.id == room);
    _apply(
      _question.copyWith(feeCodes: fees, classroomId: roomKnown ? room : null),
      reload: true,
    );
  }

  void _apply(FeeControlQuestion next, {required bool reload}) {
    setState(() => _question = next);
    FeeControlQuestion.lastVisit = next;
    next.writeLocation(context);
    final bloc = context.read<FeeControlBloc>();
    // Le montant part en centimes, sans devise : celle de l'état est peut-être
    // encore celle de la classe précédente, ou pas encore lue (B1-B2).
    if (!reload && bloc.state.lastQuery != null) {
      bloc.add(
        FeeControlSituationRequested(
          next.situation,
          thresholdInCents: next.requestedThresholdInCents,
        ),
      );
      return;
    }
    final request = next.toRequest();
    if (request == null) return;
    bloc.add(
      FeeControlSearchRequested(
        academicYearId: widget.academicYearId,
        request: request,
      ),
    );
  }

  void _onFees(List<String> fees) =>
      _apply(_question.copyWith(feeCodes: fees), reload: true);

  void _onClassroom(String id) =>
      _apply(_question.copyWith(classroomId: id), reload: true);

  void _onSituation(FeeControlPaymentFilter filter) {
    if (!filter.needsThreshold) _threshold.clear();
    _apply(
      _question.copyWith(
        situation: filter,
        thresholdInCents: filter.needsThreshold
            ? _question.thresholdInCents
            : null,
      ),
      reload: false,
    );
  }

  void _onAmount(String text) {
    final units = int.tryParse(text);
    _apply(
      _question.copyWith(thresholdInCents: units == null ? null : units * 100),
      reload: false,
    );
  }

  /// La classe porte deux devises : « a payé au moins… » tombe, la situation
  /// revient à « Tous » (R3, A4).
  void _onCurrencies(FeeControlState state) {
    if (state.atLeastAvailable || !_question.situation.needsThreshold) return;
    _threshold.clear();
    _apply(
      _question.copyWith(
        situation: FeeControlPaymentFilter.all,
        thresholdInCents: null,
      ),
      reload: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final titles = context.watch<FeeSectionTitlesCubit>().state;

    return MultiBlocListener(
      listeners: [
        BlocListener<FeeControlBloc, FeeControlState>(
          listenWhen: (p, c) => p.catalogStatus != c.catalogStatus,
          listener: (_, state) => _onCatalog(state),
        ),
        BlocListener<FeeControlBloc, FeeControlState>(
          listenWhen: (p, c) => p.currencies != c.currencies,
          listener: (_, state) => _onCurrencies(state),
        ),
      ],
      child: BlocBuilder<FeeControlBloc, FeeControlState>(
        buildWhen: (p, c) =>
            p.catalogStatus != c.catalogStatus ||
            p.natures != c.natures ||
            p.classrooms != c.classrooms ||
            p.breakdown != c.breakdown ||
            p.currencies != c.currencies,
        builder: (context, state) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => RecouvrementPerimeterBar(
                fees: RecouvrementFeePickerField(
                  natures: state.natures,
                  selected: _question.feeCodes,
                  titles: titles,
                  sheetTitle: l10n.recouvrementFeesQuestion,
                  narrow:
                      constraints.maxWidth < AppBreakpoints.dataTableCardsMax,
                  enabled: state.natures.isNotEmpty,
                  onChanged: _onFees,
                ),
                scope: FeeControlClassroomSelect(
                  classrooms: state.classrooms,
                  groups: widget.groups,
                  value: _question.classroomId,
                  onChanged: _onClassroom,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md + 2),
            FeeControlSituationCard(
              selected: _question.situation,
              counts: state.breakdown,
              currency: state.soleCurrency,
              atLeastAvailable: state.atLeastAvailable,
              thresholdController: _threshold,
              onChanged: _onSituation,
              onThresholdChanged: _onAmount,
            ),
          ],
        ),
      ),
    );
  }
}
