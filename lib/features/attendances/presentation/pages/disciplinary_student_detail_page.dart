import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/components/app_bars/student_detail_app_bar.dart';
import 'package:school_app_flutter/core/theme/app_motion.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/disciplinary_status.dart';
import 'package:school_app_flutter/features/attendances/domain/entities/offline/offline_disciplinary_case.dart';
import 'package:school_app_flutter/features/attendances/domain/usecases/offline/sync_disciplinary_pull_usecase.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_bloc.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_event.dart';
import 'package:school_app_flutter/features/attendances/presentation/bloc/offline/disciplinary_case_offline_state.dart';
import 'package:school_app_flutter/features/attendances/presentation/context/disciplinary_student_detail_intent.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_detail_context_error.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_dossier_body.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/disciplinary_open_cases_pill.dart';
import 'package:school_app_flutter/features/attendances/presentation/widgets/presence_summary/student_attendance_summary_tab.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/permission_gate.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_routes_names.dart';

/// Coquille de la fiche élève (Liste disciplines ▸ détail) : AppBar d'identité
/// (fond Bleu Profond, avatar + nom, pastille cas ouverts), barre d'onglets
/// `DossierTabs` (Discipline puis Présence) et panneau teinté de l'onglet
/// actif. Le contenu des onglets vit dans leurs specs respectives (cas
/// disciplinaires / synthèse de présence).
///
/// **Le volet Discipline est gardé par `discipline.read`, indépendamment de la
/// route.** Celle-ci est cadrée sur son second segment (`presences`), donc sur
/// `attendance.read` : sans garde interne, un profil qui ne fait que l'appel
/// voyait l'onglet et une pastille verte « Aucun cas ouvert » — une affirmation
/// qu'il n'a pas le droit de vérifier, et qui est fausse dès que l'élève est
/// sous sanction. Le volet est donc **retiré**, pas commenté (même doctrine que
/// `PermissionGate`), et les cas ne sont ni lus ni tirés du serveur.
class DisciplinaryStudentDetailPage extends StatefulWidget {
  final DisciplinaryStudentDetailIntent intent;

  const DisciplinaryStudentDetailPage({super.key, required this.intent});

  @override
  State<DisciplinaryStudentDetailPage> createState() =>
      _DisciplinaryStudentDetailPageState();
}

class _DisciplinaryStudentDetailPageState
    extends State<DisciplinaryStudentDetailPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  /// Vrai une fois les cas demandés au BLoC, pour ne pas les redemander à
  /// chaque bascule de droits.
  bool _casesRequested = false;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fadeController.forward();
      _ensureCasesLoaded();
    });
  }

  /// Vrai si la session a le droit de lire les cas disciplinaires.
  ///
  /// Lecture ponctuelle : l'abonnement qui la maintient à jour est posé par
  /// [_withPermissionWatch].
  bool get _canReadDiscipline =>
      PermissionGate.allows(context, const [Perm.disciplineRead]);

  /// Charge les cas — et les tire du serveur — **si et seulement si** la
  /// session en a le droit. Sans lui, aucune requête locale ni réseau : le
  /// volet n'est pas affiché, il n'y a rien à alimenter.
  void _ensureCasesLoaded() {
    if (_casesRequested || !_canReadDiscipline) return;
    _casesRequested = true;
    context.read<DisciplinaryCaseOfflineBloc>().add(_loadEvent());
    // 2ᵉ signal d'hydratation (le 1er = PullCoordinator au retour online) :
    // une tablette démarrée déjà connectée doit tirer les cas serveur au
    // montage. Best-effort ; au retour, on recharge (fraîcheur + nouveaux cas).
    _hydrateFromServer();
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

  /// Rebâtit la fiche quand l'ensemble des droits change en cours de session :
  /// [PermissionGate.allows] est une lecture ponctuelle, sans quoi la structure
  /// resterait figée sur les droits observés au montage. Absent de l'arbre en
  /// test, l'[AuthBloc] rend l'enveloppe transparente — même convention que
  /// `PermissionGate`.
  Widget _withPermissionWatch({required Widget child}) {
    final authBloc = PermissionGate.maybeBlocOf(context);
    if (authBloc == null) return child;

    return BlocListener<AuthBloc, AuthState>(
      bloc: authBloc,
      listenWhen: (prev, curr) =>
          !listEquals(prev.permissions, curr.permissions),
      listener: (_, _) {
        if (!mounted) return;
        setState(_ensureCasesLoaded);
      },
      child: child,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final intent = widget.intent;

    if (!intent.hasDisplayContext) {
      return const DisciplinaryDetailContextError();
    }

    return _withPermissionWatch(
      child: BlocBuilder<DisciplinaryCaseOfflineBloc, DisciplinaryCaseOfflineState>(
        // Ne reconstruit que sur les états d'affichage : un état transitoire
        // d'écriture laisse le dernier compte à l'écran.
        buildWhen: (prev, curr) =>
            curr is DisciplinaryOfflineInitial ||
            curr is DisciplinaryOfflineLoading ||
            curr is DisciplinaryOfflineCasesLoaded ||
            curr is DisciplinaryOfflineError,
        builder: (context, state) {
          // Compte connu seulement une fois la liste chargée (sinon la pastille
          // afficherait « Aucun cas ouvert » pendant le chargement). Sans le
          // droit de lecture, il n'est jamais connu : la pastille se tait.
          final int? openCount =
              _canReadDiscipline && state is DisciplinaryOfflineCasesLoaded
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
              child: _canReadDiscipline
                  ? DisciplinaryDossierBody(
                      intent: intent,
                      openCasesCount: openCount ?? 0,
                    )
                  : StudentAttendanceSummaryTab(
                      studentId: intent.studentId,
                      academicYearId: intent.academicYearId,
                    ),
            ),
          );
        },
      ),
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
}
