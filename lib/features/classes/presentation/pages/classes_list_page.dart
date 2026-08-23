import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/core/widgets/app_snack_bar.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/classes/domain/entities/classroom_member.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_intent.dart';
import 'package:school_app_flutter/features/classes/presentation/context/classes_list_policy.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/classroom_state.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_bloc.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_event.dart';
import 'package:school_app_flutter/features/classes/presentation/bloc/offline/classroom_offline_state.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_export_helper.dart';
import 'package:school_app_flutter/features/classes/presentation/helpers/classes_list_page_helpers.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_models.dart';
import 'package:school_app_flutter/features/classes/presentation/widgets/classes_list_page_content.dart';
import 'package:school_app_flutter/features/enrollment/domain/entities/enrollment_summary.dart';
import 'package:school_app_flutter/features/enrollment/offline/presentation/bloc/enrollment_local_list_bloc.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';

class ClassesListPage extends StatefulWidget {
  final ClassesListIntent intent;

  const ClassesListPage({super.key, required this.intent});

  @override
  State<ClassesListPage> createState() => _ClassesListPageState();
}

class _ClassesListPageState extends State<ClassesListPage> {
  ClassesListSearchRequest? _lastRequest;
  late ClassesListPolicy _policy;

  /// Garde-fou : un seul pull des classes/rosters par montage (CF2).
  bool _classroomsPullRequested = false;

  @override
  void initState() {
    super.initState();
    _policy = ClassesListPolicyResolver.fromIntent(widget.intent);
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
  void didUpdateWidget(covariant ClassesListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intent != widget.intent) {
      _policy = ClassesListPolicyResolver.fromIntent(widget.intent);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppPageBackground(
      child: MultiBlocListener(
        listeners: [
          // Consultation offline-first (CF3) : dès que l'année courante est
          // connue, peupler le cache local classes/rosters (pull CF2) pour que
          // la lecture du roster (ClassroomBloc, redirigée en local) trouve des
          // données. Une seule fois par montage.
          BlocListener<AcademicYearContextBloc, AcademicYearContextState>(
            listenWhen: (previous, current) =>
                previous.status != current.status &&
                current.status == AcademicYearContextLoadStatus.success,
            listener: (context, state) {
              final academicYearId = state.context?.academicYear.id ?? '';
              if (academicYearId.isEmpty) {
                return;
              }
              // Lecture locale immédiate pour peupler le dropdown (données
              // déjà en cache) + pull best-effort une seule fois par montage.
              context.read<ClassroomOfflineBloc>().add(
                OfflineClassroomsRequested(academicYearId: academicYearId),
              );
              if (_classroomsPullRequested) {
                return;
              }
              _classroomsPullRequested = true;
              // Sans année : le pull passe par le `PullCoordinator`, dont les
              // handlers Classe résolvent la courante eux-mêmes — la même que
              // celle que cet écran vient de recevoir (ADR-015 F6).
              context.read<ClassroomOfflineBloc>().add(
                const ClassroomsSyncRequested(),
              );
            },
          ),
          BlocListener<EnrollmentLocalListBloc, EnrollmentLocalListState>(
            listenWhen:
                ClassesListPageHelpers.listenWhenEnrollmentStatusChanges,
            listener: (context, state) {
              if (state.summariesStatus == EnrollmentLoadStatus.failure) {
                AppSnackBar.showError(
                  context,
                  state.errorMessage ?? l10n.classesOrganisationErrorUnknown,
                );
              }
            },
          ),
          BlocListener<ClassroomBloc, ClassroomState>(
            listenWhen:
                ClassesListPageHelpers.listenWhenClassroomMembersStatusChanges,
            listener: (context, state) {
              if (state.membersStatus == ClassroomStatus.failure) {
                AppSnackBar.showError(
                  context,
                  ClassesListPageHelpers.mapClassroomErrorToMessage(
                    l10n,
                    state.membersErrorType,
                  ),
                );
              }
            },
          ),
          // Consultation offline-first : le pull des classes/rosters est
          // découplé de la lecture, best-effort (comme les autres modules
          // offline — attendance/finance). Son échec (pas de réseau) N'EST PAS
          // surfacé : le roster affiché reste celui déjà en cache local, et un
          // retour online relancera le pull via le PullCoordinator. On ne relit
          // le roster que si le pull a abouti.
          BlocListener<ClassroomOfflineBloc, ClassroomOfflineState>(
            listenWhen: (previous, current) =>
                previous.syncStatus != current.syncStatus,
            listener: (context, state) {
              if (state.syncStatus != ClassroomStatus.success) {
                return;
              }
              final academicYearId =
                  context
                      .read<AcademicYearContextBloc>()
                      .state
                      .context
                      ?.academicYear
                      .id ??
                  '';
              if (academicYearId.isEmpty) {
                return;
              }
              // Re-lit les classes en local (dropdown à jour après le pull).
              context.read<ClassroomOfflineBloc>().add(
                OfflineClassroomsRequested(academicYearId: academicYearId),
              );
              final request = _lastRequest;
              if (request == null ||
                  !request.targetsClassroom ||
                  request.selectedClassroom == null) {
                return;
              }
              context.read<ClassroomBloc>().add(
                ClassroomMembersRequested(
                  classroomId: request.selectedClassroom!.id,
                  academicYearId: academicYearId,
                ),
              );
            },
          ),
        ],
        child: BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
          buildWhen: ClassesListPageHelpers.buildWhenAcademicYearContextChanges,
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

            final classrooms = context
                .watch<ClassroomOfflineBloc>()
                .state
                .classrooms;
            final options = ClassesListPageHelpers.buildCycleOptions(
              academicYearState.context!.schoolLevelGroups,
              classrooms,
            );

            return ClassesListPageContent(
              options: options,
              lastRequest: _lastRequest,
              onSearch: _handleSearch,
              onExportPressed: _handleExport,
              onPageRequested: _onPageRequested,
              onEnrollmentViewRequested: _onEnrollmentViewRequested,
              onClassroomMemberViewRequested: _onClassroomMemberViewRequested,
            );
          },
        ),
      ),
    );
  }

  void _handleSearch(ClassesListSearchRequest request) {
    final academicYearContext = context
        .read<AcademicYearContextBloc>()
        .state
        .context;
    final academicYearId = academicYearContext?.academicYear.id ?? '';
    if (academicYearId.isEmpty) {
      return;
    }
    if (!request.hasAnyCriteria) {
      return;
    }

    setState(() => _lastRequest = request);

    if (request.targetsClassroom && request.selectedClassroom != null) {
      context.read<EnrollmentLocalListBloc>().add(
        const LocalListResetRequested(),
      );
      context.read<ClassroomBloc>().add(
        ClassroomMembersRequested(
          classroomId: request.selectedClassroom!.id,
          academicYearId: academicYearId,
        ),
      );
      return;
    }

    context.read<ClassroomBloc>().add(const ClassroomResetRequested());
    // Lecture LOCALE des élèves réellement inscrits l'année courante (dossiers
    // finalisés) — même source que la Facturation. Le mode identité part sans
    // niveau ni cycle : le bloc les traite alors comme absents plutôt que comme
    // un filtre sur la chaîne vide, et c'est la LIGNE qui rend le niveau de
    // chaque élève trouvé.
    context.read<EnrollmentLocalListBloc>().add(
      LocalListByEnrolledAcademicInfoRequested(
        academicYearId: academicYearId,
        firstName: request.firstName,
        lastName: request.lastName,
        surname: request.surname,
        schoolLevelGroupId: request.selectedLevel?.schoolLevelGroupId ?? '',
        schoolLevelId: request.selectedLevel?.schoolLevelId ?? '',
      ),
    );
  }

  void _onPageRequested(int page) {
    context.read<EnrollmentLocalListBloc>().add(
      LocalListPageRequested(page: page),
    );
  }

  Future<void> _handleExport() async {
    final l10n = AppLocalizations.of(context)!;
    final request = _lastRequest;
    if (request == null) {
      AppSnackBar.showWarning(context, l10n.classesListExportNothingToExport);
      return;
    }

    try {
      final csv = request.targetsClassroom
          ? _buildClassroomExport(l10n, request)
          : _buildEnrollmentExport(l10n, request);

      if (csv == null || csv.trim().isEmpty) {
        AppSnackBar.showWarning(context, l10n.classesListExportNothingToExport);
        return;
      }

      await Clipboard.setData(ClipboardData(text: csv));
      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(context, l10n.classesListExportSuccess);
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, l10n.classesListExportFailed);
    }
  }

  String? _buildEnrollmentExport(
    AppLocalizations l10n,
    ClassesListSearchRequest request,
  ) {
    final bloc = context.read<EnrollmentLocalListBloc>();
    if (bloc.state.summariesStatus != EnrollmentLoadStatus.success) {
      return null;
    }

    // TOUS les résultats, pas la page affichée : un export tronqué à dix lignes
    // sous un décompte qui en annonce quarante ne se voit pas à l'ouverture du
    // fichier.
    final summaries = bloc.loadedSummaries;
    if (summaries.isEmpty) {
      return null;
    }

    return ClassesListExportHelper.buildEnrollmentCsv(
      l10n: l10n,
      summaries: summaries,
      includeLevel: request.isIdentityMode,
    );
  }

  String? _buildClassroomExport(
    AppLocalizations l10n,
    ClassesListSearchRequest request,
  ) {
    final classroomState = context.read<ClassroomBloc>().state;
    if (classroomState.membersStatus != ClassroomStatus.success) {
      return null;
    }

    final members = ClassesListPageHelpers.filterMembers(
      classroomState.members,
      request,
    );
    if (members.isEmpty) {
      return null;
    }

    return ClassesListExportHelper.buildClassroomMembersCsv(
      l10n: l10n,
      members: members,
    );
  }

  void _onEnrollmentViewRequested(EnrollmentSummary summary) {
    _policy.onEnrollmentViewRequested(context, summary, request: _lastRequest);
  }

  void _onClassroomMemberViewRequested(ClassroomMember member) {
    _policy.onClassroomMemberViewRequested(
      context,
      member,
      request: _lastRequest,
    );
  }
}
