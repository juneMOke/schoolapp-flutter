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
      child: BlocListener<ClassroomOfflineBloc, ClassroomOfflineState>(
        // Deux gestes distincts sur le BLoC offline :
        //  - TRANSFERT (A→B) : OFFLINE, événement + outbox → toast « en attente
        //    de synchro » (acquis en local, la synchro suivra) ;
        //  - AFFECTATION d'un non-réparti : ONLINE (distribution) → PUT + re-pull.
        // Les lectures (aperçu) restent sur ClassroomBloc online.
        listenWhen: (previous, current) =>
            previous.reassignStatus != current.reassignStatus ||
            previous.transferStatus != current.transferStatus,
        listener: (context, state) {
          if (state.transferStatus == ClassroomStatus.success) {
            AppSnackBar.showSuccess(
              context,
              l10n.classesOrganisationTransferQueued,
            );
            final selectedLevel = _selectedLevel;
            if (selectedLevel != null) {
              _loadOverviewIfNeeded(selectedLevel);
            }
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
          if (state.reassignStatus == ClassroomStatus.success) {
            // Succès partiel (Right(false)) : affectation serveur acquise mais
            // re-pull local KO → message nuancé. Les lectures étant online, on
            // recharge quand même l'aperçu qui reflète l'état serveur à jour.
            AppSnackBar.showSuccess(
              context,
              state.reassignRePullFailed
                  ? l10n.offlineQueuedGeneric
                  : l10n.classesOrganisationTransferSuccess,
            );
            final selectedLevel = _selectedLevel;
            if (selectedLevel != null) {
              _loadOverviewIfNeeded(selectedLevel);
            }
          }
          if (state.reassignStatus == ClassroomStatus.failure) {
            AppSnackBar.showError(
              context,
              ClassesOrganisationPageHelpers.mapClassroomErrorToMessage(
                l10n,
                state.reassignErrorType,
              ),
            );
          }
        },
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

  Future<void> _handleReassignTap(ClassroomMemberReassignIntent intent) async {
    final l10n = AppLocalizations.of(context)!;
    // Anti-double-envoi : transfert (offline) ou affectation (online) en cours.
    final offlineState = context.read<ClassroomOfflineBloc>().state;
    if (offlineState.transferStatus == ClassroomStatus.loading ||
        offlineState.reassignStatus == ClassroomStatus.loading) {
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

  void _loadOverviewIfNeeded(ClassesOrganisationLevelOption level) {
    // On charge l'aperçu de distribution dans les deux cas :
    // - niveau réparti : pour afficher les sous-classes et leurs membres ;
    // - niveau non réparti : pour rappeler l'effectif et le ratio G/F des
    //   élèves restant à répartir (tous non affectés).
    final academicYearContext = context
        .read<AcademicYearContextBloc>()
        .state
        .context;
    final academicYearId = academicYearContext?.academicYear.id ?? '';
    if (academicYearId.isEmpty) {
      return;
    }

    // Aperçu online : ne sert plus qu'à alimenter le nombre d'élèves non
    // affectés (aucun équivalent dans le miroir local des classes).
    context.read<ClassroomBloc>().add(
      ClassroomDistributionOverviewRequested(
        academicYearId: academicYearId,
        schoolLevelId: level.schoolLevelId,
      ),
    );

    // Niveau réparti : classes + rosters composés LOCAUX (miroir ± transferts
    // pending) — source primaire de l'affichage, sans re-pull serveur ici.
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
