import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/components/app_bars/student_detail_app_bar.dart';
import 'package:school_app_flutter/core/constants/app_colors.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/constants/app_text_styles.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/sync_disciplinary_pull_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/context/disciplinary_student_detail_intent.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_case_create_dialog.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_cases_tab.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_detail_back_button.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_dossier_tabs.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_open_cases_pill.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/student_attendance_summary_tab.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Coquille de la fiche élève (Liste disciplines ▸ détail) : AppBar d'identité
/// (fond Bleu Profond, avatar + nom, pastille cas ouverts), barre d'onglets
/// `DossierTabs` (Discipline puis Présence) et panneau teinté de l'onglet
/// actif. Le contenu des onglets vit dans leurs specs respectives (cas
/// disciplinaires / synthèse de présence).
class DisciplinaryStudentDetailPage extends StatefulWidget {
  final DisciplinaryStudentDetailIntent intent;

  const DisciplinaryStudentDetailPage({super.key, required this.intent});

  @override
  State<DisciplinaryStudentDetailPage> createState() =>
      _DisciplinaryStudentDetailPageState();
}

class _DisciplinaryStudentDetailPageState
    extends State<DisciplinaryStudentDetailPage>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: AppMotion.standard,
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppMotion.outCurve,
    );
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fadeController.forward();
      context.read<DisciplinaryCaseOfflineBloc>().add(_loadEvent());
      // 2ᵉ signal d'hydratation (le 1er = PullCoordinator au retour online) :
      // une tablette démarrée déjà connectée doit tirer les cas serveur au
      // montage. Best-effort ; au retour, on recharge (fraîcheur + nouveaux cas).
      _hydrateFromServer();
    });
  }

  LoadOfflineDisciplinaryCases _loadEvent() => LoadOfflineDisciplinaryCases(
    studentId: widget.intent.studentId,
    academicYearId: widget.intent.academicYearId,
  );

  Future<void> _hydrateFromServer() async {
    await GetIt.I<SyncDisciplinaryPullUseCase>().call();
    if (!mounted) return;
    context.read<DisciplinaryCaseOfflineBloc>().add(_loadEvent());
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intent = widget.intent;

    if (!intent.hasDisplayContext) {
      return _buildContextError(context, l10n);
    }

    return BlocBuilder<
      DisciplinaryCaseOfflineBloc,
      DisciplinaryCaseOfflineState
    >(
      // Ne reconstruit que sur les états d'affichage : un état transitoire
      // d'écriture laisse le dernier compte à l'écran.
      buildWhen: (prev, curr) =>
          curr is DisciplinaryOfflineInitial ||
          curr is DisciplinaryOfflineLoading ||
          curr is DisciplinaryOfflineCasesLoaded ||
          curr is DisciplinaryOfflineError,
      builder: (context, state) {
        // Compte connu seulement une fois la liste chargée (sinon la pastille
        // afficherait « Aucun cas ouvert » pendant le chargement).
        final int? openCount = state is DisciplinaryOfflineCasesLoaded
            ? _openCasesCount(state.cases)
            : null;

        return AppPageBackground(
          scrollable: false,
          appBar: StudentDetailAppBar(
            fullName: _studentFullName(l10n),
            eyebrow: _studentEyebrow(l10n),
            firstName: intent.studentFirstName,
            lastName: intent.studentLastName,
            fallbackRoute: AppRoutesNames.presences,
            trailing: DisciplinaryOpenCasesAppBarPill(
              openCasesCount: openCount,
              openLabel: l10n.dossierOpenCasesChip(openCount ?? 0),
              noneLabel: l10n.dossierNoOpenCases,
            ),
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DisciplinaryDossierTabs(
                  controller: _tabController,
                  openCasesCount: openCount ?? 0,
                ),
                const SizedBox(height: AppDimensions.spacingM),
                // Le contenu des onglets s'affiche directement sur le fond
                // décoré standard de la page (halos + motif), comme les
                // autres pages : plus de panneau peignant un fond plein qui
                // le masquerait.
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      DisciplinaryCasesTab(
                        studentId: intent.studentId,
                        academicYearId: intent.academicYearId,
                        onCreateCase: () => _showCreateDialog(context),
                      ),
                      StudentAttendanceSummaryTab(
                        studentId: intent.studentId,
                        academicYearId: intent.academicYearId,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Nom complet affiché dans l'AppBar (post-nom prénom).
  String _studentFullName(AppLocalizations l10n) {
    final intent = widget.intent;
    final fullName = [
      intent.studentLastName,
      intent.studentMiddleName,
      intent.studentFirstName,
    ].where((p) => (p ?? '').trim().isNotEmpty).join(' ').trim();
    return fullName.isEmpty ? l10n.disciplinaryUnknownValue : fullName;
  }

  /// Sur-titre « classe · niveau » affiché au-dessus du nom dans l'AppBar.
  String _studentEyebrow(AppLocalizations l10n) {
    final intent = widget.intent;
    final parts = [
      intent.classroomName,
      intent.levelName,
    ].where((value) => value.trim().isNotEmpty).map((value) => value.trim());
    final eyebrow = parts.join(' · ');
    return eyebrow.isEmpty ? l10n.disciplinaryUnknownValue : eyebrow;
  }

  int _openCasesCount(List<OfflineDisciplinaryCase> cases) => cases
      .where(
        (c) =>
            c.status == DisciplinaryStatus.open ||
            c.status == DisciplinaryStatus.pending,
      )
      .length;

  Widget _buildContextError(BuildContext context, AppLocalizations l10n) {
    return AppPageBackground(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.report_problem_outlined,
              size: 40,
              color: AppColors.warning.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingM),
          Text(
            l10n.disciplinaryDetailContextErrorTitle,
            style: AppTextStyles.sectionTitle.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            l10n.disciplinaryDetailContextErrorMessage,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimensions.spacingL),
          DisciplinaryDetailBackButton(
            label: l10n.disciplinaryDetailBackLabel,
            fallbackRoute: AppRoutesNames.presences,
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    // Écriture offline-first : le dialog dispatche sur le BLoC offline (scopé
    // par AttendanceFeatureScope). showDialog monte sous le Navigator racine,
    // hors du scope : on relaie donc le BLoC via .value.
    final disciplinaryCaseOfflineBloc = context
        .read<DisciplinaryCaseOfflineBloc>();
    final studentId = widget.intent.studentId;
    final academicYearId = widget.intent.academicYearId;

    showDialog(
      context: context,
      builder: (context) => BlocProvider<DisciplinaryCaseOfflineBloc>.value(
        value: disciplinaryCaseOfflineBloc,
        child: DisciplinaryCaseCreateDialog(
          studentId: studentId,
          studentFirstName: widget.intent.studentFirstName,
          studentLastName: widget.intent.studentLastName,
          studentMiddleName: widget.intent.studentMiddleName,
          studentGender: widget.intent.studentGender,
          academicYearId: academicYearId,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      // La liste locale se recharge (le dialog a enfilé une création → l'onglet
      // recharge sur CasePendingSync ; on force aussi ici pour l'en-tête).
      disciplinaryCaseOfflineBloc.add(
        LoadOfflineDisciplinaryCases(
          studentId: studentId,
          academicYearId: academicYearId,
        ),
      );
    });
  }
}
