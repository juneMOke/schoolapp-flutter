import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_organisation_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_state.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_distribution_result_dialog.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_page_content.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_organisation_reassign_dialog.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesOrganisationPage extends StatefulWidget {
  const ClassesOrganisationPage({super.key});

  @override
  State<ClassesOrganisationPage> createState() =>
      _ClassesOrganisationPageState();
}

class _ClassesOrganisationPageState extends State<ClassesOrganisationPage> {
  String? _selectedCycleId;
  ClassesOrganisationLevelOption? _selectedLevel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AcademicYearContextBloc>().add(
        const AcademicYearContextRequested(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPageBackground(
      // Deux gestes distincts sur le BLoC offline, donc DEUX listeners séparés :
      //  - TRANSFERT (A→B) : OFFLINE, événement + outbox → toast « en attente
      //    de synchro » (acquis en local, la synchro suivra) ;
      //  - AFFECTATION d'un non-réparti : ONLINE (POST members) → création du
      //    membre, intégration au miroir, re-pull.
      // Un listener UNIQUE ne conviendrait pas : les deux statuts sont collants
      // (ils restent `success`/`failure` après le geste), si bien qu'une
      // notification déclenchée par l'un rejouait le toast terminal de l'autre —
      // p. ex. « Élève affecté » re-tiré à chaque étape du transfert suivant.
      // Chaque listener ne s'abonne donc qu'à SON propre statut.
      // Dans les deux cas, le rechargement post-succès (`_loadOverviewIfNeeded`)
      // reste purement LOCAL : aucun appel réseau ne doit être déclenché par un
      // transfert (censé fonctionner hors connexion) ni par une affectation.
      child: MultiBlocListener(
        listeners: [
          BlocListener<ClassroomOfflineBloc, ClassroomOfflineState>(
            listenWhen: (previous, current) =>
                previous.transferStatus != current.transferStatus,
            listener: (context, state) => _onTransferStatusChanged(state, l10n),
          ),
          BlocListener<ClassroomOfflineBloc, ClassroomOfflineState>(
            listenWhen: (previous, current) =>
                previous.assignStatus != current.assignStatus,
            listener: (context, state) => _onAssignStatusChanged(state, l10n),
          ),
        ],
        child: BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
          buildWhen: ClassesOrganisationPageHelpers
              .buildWhenAcademicYearContextChanges,
          builder: (context, academicYearState) {
            if (academicYearState.status ==
                    AcademicYearContextLoadStatus.loading ||
                academicYearState.status ==
                    AcademicYearContextLoadStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (academicYearState.status !=
                    AcademicYearContextLoadStatus.success ||
                academicYearState.context == null) {
              return BootstrapContextError(
                onLogout: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                },
              );
            }

            final options = ClassesOrganisationPageHelpers.buildAcademicOptions(
              academicYearState.context!.schoolLevelGroups,
            );
            final cycles = ClassesOrganisationPageHelpers.buildCycleOptions(
              options,
            );
            final schoolYear = academicYearState.context!.academicYear.name;

            return ClassesOrganisationPageContent(
              schoolYear: schoolYear,
              cycles: cycles,
              selectedCycleId: _selectedCycleId,
              selectedLevel: _selectedLevel,
              isDistributing:
                  context.watch<ClassroomBloc>().state.distributionStatus ==
                  ClassroomStatus.loading,
              onDistributionRequested: _handleDistributionRequested,
              onCycleChanged: _handleCycleChanged,
              onLevelChanged: _handleLevelChanged,
              onTransferTap: _handleReassignTap,
            );
          },
        ),
      ),
    );
  }

  /// Issue du TRANSFERT (offline) : le geste est acquis en local dès que
  /// l'événement est enfilé, d'où le message « en attente de synchro ».
  void _onTransferStatusChanged(
    ClassroomOfflineState state,
    AppLocalizations l10n,
  ) {
    if (state.transferStatus == ClassroomStatus.success) {
      AppSnackBar.showSuccess(context, l10n.classesOrganisationTransferQueued);
      final selectedLevel = _selectedLevel;
      if (selectedLevel != null) {
        _loadOverviewIfNeeded(selectedLevel);
      }
      return;
    }
    if (state.transferStatus == ClassroomStatus.failure) {
      AppSnackBar.showError(
        context,
        ClassesOrganisationPageHelpers.mapClassroomErrorToMessage(
          l10n,
          state.transferErrorType,
        ),
      );
    }
  }

  /// Issue de l'AFFECTATION d'un non-réparti (online).
  void _onAssignStatusChanged(
    ClassroomOfflineState state,
    AppLocalizations l10n,
  ) {
    if (state.assignStatus == ClassroomStatus.success) {
      // Succès partiel (Right(false)) : affectation serveur acquise mais
      // miroir local pas à jour → message nuancé. Le rechargement reste
      // local (la vérité est côté serveur, à re-synchroniser plus tard).
      AppSnackBar.showSuccess(
        context,
        state.assignRePullFailed
            ? l10n.offlineQueuedGeneric
            : l10n.classesOrganisationAssignSuccess,
      );
      final selectedLevel = _selectedLevel;
      if (selectedLevel != null) {
        _loadOverviewIfNeeded(selectedLevel);
      }
      return;
    }
    if (state.assignStatus == ClassroomStatus.failure) {
      AppSnackBar.showError(
        context,
        ClassesOrganisationPageHelpers.mapAssignErrorToMessage(
          l10n,
          state.assignErrorType,
        ),
      );
    }
  }

  Future<void> _handleReassignTap(ClassroomMemberReassignIntent intent) async {
    final l10n = AppLocalizations.of(context)!;
    // Anti-double-envoi : transfert (offline) ou affectation (online) en cours.
    final offlineState = context.read<ClassroomOfflineBloc>().state;
    if (offlineState.transferStatus == ClassroomStatus.loading ||
        offlineState.assignStatus == ClassroomStatus.loading) {
      AppSnackBar.showInfo(context, l10n.classesOrganisationTransferInProgress);
      return;
    }

    final selectedLevel = _selectedLevel;
    if (selectedLevel == null) {
      return;
    }

    // Classes cibles proposées depuis les données LOCALES (classes + rosters
    // composés du niveau) : cohérent avec l'affichage de l'écran, qui lit déjà
    // ces mêmes données. Rien à proposer tant que le niveau n'est pas chargé.
    if (offlineState.levelClassrooms.isEmpty) {
      return;
    }

    // Toutes les classes du niveau sont proposées : la popin marque la classe
    // actuelle « Actuelle » et les classes pleines « Complet » (désactivées).
    // `levelClassrooms` est un working-set DÉDIÉ à ce niveau (jamais partagé
    // avec le dropdown année complète des autres pages) : un filtre défensif
    // supplémentaire écarte malgré tout toute classe d'un autre niveau.
    final options = offlineState.levelClassrooms
        .where(
          (offlineClassroom) =>
              offlineClassroom.schoolLevelId == selectedLevel.schoolLevelId,
        )
        .map((offlineClassroom) {
          final members =
              offlineState.levelRosters[offlineClassroom.id] ??
              const <ClassroomMember>[];
          return ClassroomReassignOption(
            id: offlineClassroom.id,
            name: offlineClassroom.name,
            totalCount: members.length,
            capacity: offlineClassroom.capacity ?? 0,
            femaleCount: members
                .where(
                  (member) =>
                      member.studentGender == ClassroomMemberGender.female,
                )
                .length,
            maleCount: members
                .where(
                  (member) =>
                      member.studentGender == ClassroomMemberGender.male,
                )
                .length,
          );
        })
        .toList(growable: false);

    // Au moins une classe doit être sélectionnable : ni la classe actuelle, ni
    // une classe pleine. Sinon (niveau mono-classe en transfert, ou toutes
    // pleines), on prévient sans ouvrir une popin sans issue.
    final hasSelectableTarget = options.any(
      (option) => !option.isFull && option.id != intent.classroomId,
    );
    if (!hasSelectableTarget) {
      AppSnackBar.showWarning(
        context,
        l10n.classesOrganisationTransferNoTarget,
      );
      return;
    }

    await showClassesOrganisationReassignDialog(
      context: context,
      intent: intent,
      options: options,
      schoolLevelId: selectedLevel.schoolLevelId,
    );
  }

  void _handleCycleChanged(String? cycleId) {
    setState(() {
      _selectedCycleId = cycleId;
      _selectedLevel = null;
    });
    context.read<ClassroomBloc>().add(const ClassroomResetRequested());
  }

  void _handleLevelChanged(ClassesOrganisationLevelOption? level) {
    setState(() {
      _selectedLevel = level;
    });

    if (level == null) {
      context.read<ClassroomBloc>().add(const ClassroomResetRequested());
      return;
    }

    _loadOverviewIfNeeded(level);
  }

  // Rechargement 100% LOCAL (classes + rosters composés + non-affectés du
  // niveau, miroir ± transferts pending) : source primaire de l'affichage,
  // sans aucun appel réseau. Appelé après un changement de niveau ou un
  // transfert/affectation réussi — un geste qui, pour le transfert, est
  // censé rester utilisable hors connexion (CF4) : aucun appel online ne
  // doit se glisser ici.
  void _loadOverviewIfNeeded(ClassesOrganisationLevelOption level) {
    final academicYearContext = context
        .read<AcademicYearContextBloc>()
        .state
        .context;
    final academicYearId = academicYearContext?.academicYear.id ?? '';
    if (academicYearId.isEmpty) {
      return;
    }

    // Working-set DÉDIÉ à ce niveau (`levelClassrooms`), jamais partagé avec
    // le dropdown année complète des autres pages (Présences/Classes list).
    context.read<ClassroomOfflineBloc>().add(
      OfflineLevelClassroomsRequested(
        academicYearId: academicYearId,
        schoolLevelId: level.schoolLevelId,
      ),
    );
    context.read<ClassroomOfflineBloc>().add(
      OfflineLevelRostersRequested(
        academicYearId: academicYearId,
        schoolLevelId: level.schoolLevelId,
      ),
    );
    context.read<ClassroomOfflineBloc>().add(
      OfflineLevelUnassignedEnrollmentsRequested(
        academicYearId: academicYearId,
        schoolLevelId: level.schoolLevelId,
      ),
    );
  }

  // Aperçu ONLINE : sert exclusivement la récap « effectif par classe » de la
  // sur-couche de résultat de répartition (post-distribution — cf.
  // classes_organisation_distribution_result_dialog.dart,
  // distributionOverview.classrooms). La répartition étant déjà une action
  // online, ce seul appel réseau y reste légitime — il ne doit PAS être
  // déclenché par un simple changement de niveau ou par le transfert/
  // affectation (cf. [_loadOverviewIfNeeded], purement local).
  void _requestDistributionOverview(ClassesOrganisationLevelOption level) {
    final academicYearContext = context
        .read<AcademicYearContextBloc>()
        .state
        .context;
    final academicYearId = academicYearContext?.academicYear.id ?? '';
    if (academicYearId.isEmpty) {
      return;
    }

    context.read<ClassroomBloc>().add(
      ClassroomDistributionOverviewRequested(
        academicYearId: academicYearId,
        schoolLevelId: level.schoolLevelId,
      ),
    );
  }

  Future<void> _handleDistributionRequested() async {
    final level = _selectedLevel;
    if (level == null || level.splitIntoClassrooms) {
      return;
    }

    final academicYearContext = context
        .read<AcademicYearContextBloc>()
        .state
        .context;
    final academicYearId = academicYearContext?.academicYear.id ?? '';
    if (academicYearId.isEmpty) {
      return;
    }

    // La carte « Niveau non réparti » sert de surface de confirmation : le
    // bouton ouvre directement la sur-couche de résultat (PARCOURS 4), qui
    // dispatche la répartition et affiche processing → succès | échec.
    await showClassesOrganisationDistributionResultDialog(
      context: context,
      classroomBloc: context.read<ClassroomBloc>(),
      levelName: level.schoolLevelName,
      request: ClassroomDistributionRequested(
        academicYearId: academicYearId,
        schoolLevelGroupId: level.schoolLevelGroupId,
        schoolLevelId: level.schoolLevelId,
        distributionCriterion: ClassroomDistributionCriterion.gender,
      ),
      onDistributed: () => _applyDistributionSuccess(level),
    );
  }

  /// Effets de bord appliqués au SUCCÈS de la répartition : marquer le niveau
  /// comme réparti (patch référentiel local + état en mémoire) puis recharger
  /// l'aperçu pour alimenter la vue répartie et le récapitulatif de la
  /// sur-couche.
  void _applyDistributionSuccess(ClassesOrganisationLevelOption level) {
    if (!mounted) {
      return;
    }
    context.read<AcademicYearContextBloc>().add(
      AcademicYearContextSchoolLevelSplitPatched(level.schoolLevelId),
    );
    final updatedLevel = level.copyWith(splitIntoClassrooms: true);
    setState(() {
      _selectedLevel = updatedLevel;
    });
    _loadOverviewIfNeeded(updatedLevel);
    _requestDistributionOverview(updatedLevel);

    // Répartition serveur acquise mais re-pull local KO : le miroir des
    // classes n'a pas encore la nouvelle répartition (à retenter au prochain
    // retour online), pas un échec de la répartition elle-même.
    if (context.read<ClassroomBloc>().state.distributionRePullFailed) {
      AppSnackBar.showInfo(
        context,
        AppLocalizations.of(context)!.offlineQueuedGeneric,
      );
    }
  }
}
