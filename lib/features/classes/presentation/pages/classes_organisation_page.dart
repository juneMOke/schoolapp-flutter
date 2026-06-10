import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_context_bloc.dart';
import 'package:school_app_flutter/features/bootstrap/presentation/bloc/bootstrap_current_year_bloc.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_distribution_criterion.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_organisation_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
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
      context.read<BootstrapCurrentYearBloc>().add(
        const BootstrapContextLocalRequested(
          key: AppConstants.bootstrapPayloadKey,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPageBackground(
      child: BlocListener<ClassroomBloc, ClassroomState>(
        // La distribution est désormais gérée par la sur-couche de résultat
        // (PARCOURS 4) ; ce listener ne traite plus que la réassignation.
        listenWhen: ClassesOrganisationPageHelpers.listenReassignStatus,
        listener: (context, state) {
          if (state.reassignStatus == ClassroomStatus.success) {
            AppSnackBar.showSuccess(
              context,
              l10n.classesOrganisationTransferSuccess,
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
        child: BlocBuilder<BootstrapCurrentYearBloc, BootstrapContextState>(
          buildWhen: ClassesOrganisationPageHelpers.buildWhenBootstrapChanges,
          builder: (context, bootstrapState) {
            if (bootstrapState.status == BootstrapContextLoadStatus.loading ||
                bootstrapState.status == BootstrapContextLoadStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (bootstrapState.status != BootstrapContextLoadStatus.success ||
                bootstrapState.bootstrap == null) {
              return BootstrapContextError(
                onLogout: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequested());
                },
              );
            }

            final options = ClassesOrganisationPageHelpers.buildAcademicOptions(
              bootstrapState.bootstrap?.schoolLevelGroups ?? const [],
            );
            final cycles = ClassesOrganisationPageHelpers.buildCycleOptions(
              options,
            );
            final schoolYear =
                bootstrapState.bootstrap?.academicYear.name ?? '';

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
    final classroomState = context.read<ClassroomBloc>().state;
    if (classroomState.reassignStatus == ClassroomStatus.loading) {
      AppSnackBar.showInfo(context, l10n.classesOrganisationTransferInProgress);
      return;
    }

    final selectedLevel = _selectedLevel;
    if (selectedLevel == null) {
      return;
    }

    final overview = classroomState.distributionOverview;
    if (overview == null) {
      return;
    }

    // Toutes les classes du niveau sont proposées : la popin marque la classe
    // actuelle « Actuelle » et les classes pleines « Complet » (désactivées).
    final options = overview.classrooms
        .map(
          (item) => ClassroomReassignOption(
            id: item.classroom.id,
            name: item.classroom.name,
            totalCount: item.members.length,
            capacity: item.classroom.capacity,
            femaleCount: item.members
                .where(
                  (member) =>
                      member.studentGender == ClassroomMemberGender.female,
                )
                .length,
            maleCount: item.members
                .where(
                  (member) =>
                      member.studentGender == ClassroomMemberGender.male,
                )
                .length,
          ),
        )
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
    final bootstrap = context.read<BootstrapCurrentYearBloc>().state.bootstrap;
    final academicYearId = bootstrap?.academicYear.id ?? '';
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

    final bootstrap = context.read<BootstrapCurrentYearBloc>().state.bootstrap;
    final academicYearId = bootstrap?.academicYear.id ?? '';
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
  /// comme réparti (patch bootstrap + état local) puis recharger l'aperçu pour
  /// alimenter la vue répartie et le récapitulatif de la sur-couche.
  void _applyDistributionSuccess(ClassesOrganisationLevelOption level) {
    if (!mounted) {
      return;
    }
    context.read<BootstrapCurrentYearBloc>().add(
      BootstrapContextSchoolLevelSplitPatched(
        schoolLevelId: level.schoolLevelId,
        key: AppConstants.bootstrapPayloadKey,
      ),
    );
    final updatedLevel = level.copyWith(splitIntoClassrooms: true);
    setState(() {
      _selectedLevel = updatedLevel;
    });
    _loadOverviewIfNeeded(updatedLevel);
  }
}
