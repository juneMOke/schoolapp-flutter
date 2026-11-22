import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_breakpoints.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/offline/online_only.dart';
import 'package:school_app_flutter/core/theme/tokens/app_spacing.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/eteelo_page_header.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_bloc.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/fee_control_selection_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_page_actions.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/fee_control_question.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/actions/fee_control_action_bar.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/actions/fee_control_marked_card.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fee_control_results_view.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fee_control_summary_band.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/fiche/fee_control_student_panel.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/widgets/perimeter/fee_control_perimeter.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

/// **Recouvrement ▸ Contrôle des frais** (spec Recouvrement v2, page 2) : pour
/// des frais et une classe, nommer les élèves — qui a tout soldé, qui a payé
/// en partie, qui n'a rien versé, qui a atteint un montant —, puis agir sur une
/// sélection.
///
/// Toujours **dans la coquille** (R15 du tableau de bord) : le tableau de bord
/// y mène par l'adresse `/home/recouvrement-controle?frais=…&classe=…`, que
/// cette page lit une fois à l'arrivée (R12), puis tient à jour.
class FeeControlPage extends StatelessWidget {
  /// Critères posés par le tableau de bord (tests, liens) ; à défaut,
  /// l'adresse, puis la dernière visite.
  final FeeControlIntent? intent;

  const FeeControlPage({super.key, this.intent});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<FeeControlBloc>(create: (_) => getIt<FeeControlBloc>()),
        // Le titre que l'école donne à chaque nature — celui que le tableau de
        // bord et les exports écrivent aussi.
        BlocProvider<FeeSectionTitlesCubit>(
          create: (_) => getIt<FeeSectionTitlesCubit>()..load(),
        ),
        // Brouillon de séance : les cochés et les marqués « à renvoyer ».
        BlocProvider<FeeControlSelectionCubit>(
          create: (_) => FeeControlSelectionCubit(),
        ),
      ],
      child: _FeeControlView(intent: intent),
    );
  }
}

class _FeeControlView extends StatefulWidget {
  final FeeControlIntent? intent;

  const _FeeControlView({this.intent});

  @override
  State<_FeeControlView> createState() => _FeeControlViewState();
}

class _FeeControlViewState extends State<_FeeControlView> {
  /// Grand écran : l'aperçu d'un élève s'ancre à droite du tableau.
  bool _docked = false;
  String? _dockedStudentId;
  final _contentKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AcademicYearContextBloc>().add(
        const AcademicYearContextRequested(),
      );
    });
  }

  void _closeDockedSheet(String studentId) {
    if (!mounted || _dockedStudentId != studentId) return;
    setState(() => _dockedStudentId = null);
  }

  void _openSheet(FeeControlRow row, String academicYearId) {
    if (_docked) {
      setState(() => _dockedStudentId = row.studentId);
      return;
    }
    openStudentSheet(context, row, academicYearId);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _docked =
            constraints.maxWidth >= AppBreakpoints.feeControlDockedSheetMin;
        final content = KeyedSubtree(
          key: _contentKey,
          child: _content(context),
        );
        final studentId = _dockedStudentId;
        return AppPageBackground(
          width: PageContentWidth.wide,
          scrollable: !_docked,
          child: !_docked
              ? content
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: SingleChildScrollView(child: content)),
                    if (studentId != null) ...[
                      const SizedBox(width: AppDimensions.spacingL),
                      SizedBox(
                        width: AppDimensions.feeControlDockedSheetWidth,
                        child: FeeControlStudentPanel(
                          key: ValueKey(studentId),
                          studentId: studentId,
                          academicYearId:
                              context
                                  .read<AcademicYearContextBloc>()
                                  .state
                                  .context
                                  ?.academicYear
                                  .id ??
                              '',
                          onClose: () => _closeDockedSheet(studentId),
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
      buildWhen: (prev, curr) =>
          prev.status != curr.status || prev.context != curr.context,
      builder: (context, academicYearState) {
        if (academicYearState.status == AcademicYearContextLoadStatus.loading ||
            academicYearState.status == AcademicYearContextLoadStatus.initial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.spacingXL),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (academicYearState.status != AcademicYearContextLoadStatus.success) {
          return BootstrapContextError(
            onLogout: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          );
        }
        final yearContext = academicYearState.context!;
        final academicYearId = yearContext.academicYear.id;

        return BlocListener<FeeControlBloc, FeeControlState>(
          // Une sélection n'a de sens que dans son périmètre : changer de
          // frais, de classe, de situation ou de plancher la vide (R7).
          listenWhen: (prev, curr) =>
              prev.lastQuery?.copyWithPage(0) !=
              curr.lastQuery?.copyWithPage(0),
          listener: (context, _) =>
              context.read<FeeControlSelectionCubit>().clearSelection(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              EteeloPageHeader(
                eyebrow: l10n.recouvrementControlEyebrow(
                  yearContext.academicYear.name,
                ),
                title: l10n.recouvrementControlTitle,
                subtitle: l10n.recouvrementControlSubtitle,
              ),
              const SizedBox(height: AppSpacing.lg),
              FeeControlPerimeter(
                academicYearId: academicYearId,
                groups: yearContext.schoolLevelGroups,
                initial: widget.intent == null
                    ? null
                    : FeeControlQuestion.fromIntent(widget.intent!),
              ),
              const SizedBox(height: AppSpacing.lg),
              const FeeControlSummaryBand(),
              // La relance attend le réseau (Q2) : hors ligne, son bouton
              // reste en place mais inactif.
              OnlineOnly(
                builder: (context, online) => FeeControlActionBar(
                  onCallList: () => printCallSheet(context),
                  onNotify: online ? () => notifyParents(context) : null,
                  onMark: () => markSelection(context),
                ),
              ),
              FeeControlResultsView(
                titles: context.watch<FeeSectionTitlesCubit>().state,
                onViewRequested: (row) =>
                    openFinancialRecord(context, row, academicYearId),
                onRowTapped: (row) => _openSheet(row, academicYearId),
                openedStudentId: _docked ? _dockedStudentId : null,
                onBilling: () => openBilling(context),
              ),
              const FeeControlMarkedCard(),
            ],
          ),
        );
      },
    );
  }
}
