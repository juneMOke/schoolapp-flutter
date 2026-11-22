import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/constants/app_dimensions.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/core/layout/page_content_width.dart';
import 'package:school_app_flutter/core/navigation/location_query.dart';
import 'package:school_app_flutter/core/widgets/app_page_background.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/enrollment/presentation/widgets/bootstrap_context_error.dart';
import 'package:school_app_flutter/features/finance/presentation/bloc/finance/fee_section_titles_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/domain/entities/recovery_question.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_catalog_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_dashboard_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/bloc/v2/recovery_students_cubit.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/helpers/fee_control_fee_options.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/v2/recovery_dashboard_address.dart';
import 'package:school_app_flutter/features/recouvrement/presentation/pages/v2/recovery_dashboard_body.dart';
import 'package:school_app_flutter/features/treasury/presentation/widgets/common/treasury_refresh_scope.dart';

/// **Recouvrement ▸ Tableau de bord** (spec v2, page 1) : sur les frais
/// choisis, combien il reste à percevoir et où — par frais, par classe, puis
/// élève par élève —, et ce que coûterait un renvoi.
///
/// **Calculé par le serveur** (arbitrage du 2026-11-21) : chiffres, liste,
/// fiche de classe et exports répondent à la même question (R14). Hors ligne,
/// la dernière photo datée, pour la dernière question seulement. La question
/// vit dans l'adresse : un rafraîchissement ne la perd pas.
class RecouvrementDashboardPage extends StatelessWidget {
  const RecouvrementDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RecoveryDashboardCubit>(
          create: (_) => getIt<RecoveryDashboardCubit>(),
        ),
        BlocProvider<RecoveryStudentsCubit>(
          create: (_) => getIt<RecoveryStudentsCubit>(),
        ),
        BlocProvider<RecoveryCatalogCubit>(
          create: (_) => getIt<RecoveryCatalogCubit>(),
        ),
        // Le titre que l'école donne à chaque nature : celui des pastilles du
        // choix des frais, comme au contrôle.
        BlocProvider<FeeSectionTitlesCubit>(
          create: (_) => getIt<FeeSectionTitlesCubit>()..load(),
        ),
      ],
      child: const _RecouvrementDashboardView(),
    );
  }
}

class _RecouvrementDashboardView extends StatefulWidget {
  const _RecouvrementDashboardView();

  @override
  State<_RecouvrementDashboardView> createState() =>
      _RecouvrementDashboardViewState();
}

class _RecouvrementDashboardViewState
    extends State<_RecouvrementDashboardView> {
  /// La question en cours ; `null` tant que le catalogue n'a pas répondu.
  RecoveryDashboardAddress? _address;
  String? _yearId;

  /// Page de la liste : jamais dans l'adresse (§0), elle repart à la première.
  var _page = 0;

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

  void _start(String yearId) {
    if (_yearId == yearId) return;
    _yearId = yearId;
    _address = null;
    context.read<RecoveryCatalogCubit>().load(yearId);
  }

  /// Le catalogue local arrivé : la question se complète (adresse, dernière
  /// visite, dernière photo, sinon le premier frais), frais inconnus écartés.
  Future<void> _onCatalog(RecoveryCatalogState catalog) async {
    final yearId = _yearId;
    if (catalog.status != RecoveryLoadStatus.success || yearId == null) return;
    if (catalog.natures.isEmpty) return;
    final router = LocationQuery.ownedBy(context);
    final fromAddress = router == null
        ? null
        : RecoveryDashboardAddress.fromQueryParameters(
            router.routerDelegate.currentConfiguration.uri.queryParameters,
          );
    var address = fromAddress ?? RecoveryDashboardAddress.lastVisit;
    if (address == null) {
      final cached = await context
          .read<RecoveryDashboardCubit>()
          .lastCachedQuestion(yearId);
      if (!mounted) return;
      if (cached != null) {
        address = const RecoveryDashboardAddress().withQuestion(cached);
      }
    }
    final titles = context.read<FeeSectionTitlesCubit>().state;
    final known = {for (final n in catalog.natures) n.feeCode};
    final base = address ?? const RecoveryDashboardAddress();
    var fees = [
      for (final c in recouvrementSchoolOrder(base.feeCodes, titles))
        if (known.contains(c)) c,
    ];
    if (fees.isEmpty) fees = [catalog.natures.first.feeCode];
    _apply(base.copyWith(feeCodes: fees), questionChanged: true);
  }

  /// Change la question : l'adresse et la dernière visite suivent ; les
  /// chiffres se relisent si la question a changé, la liste si la question,
  /// l'onglet ou la recherche ont changé (la page repart alors à la
  /// première). [ask] faux : la question vient déjà du cubit (règle retombée
  /// en mixte), on ne la redemande pas.
  void _apply(
    RecoveryDashboardAddress next, {
    bool questionChanged = false,
    bool ask = true,
  }) {
    final yearId = _yearId;
    if (yearId == null) return;
    final previous = _address;
    final changed = questionChanged || previous?.question != next.question;
    final listChanged =
        changed || previous?.tab != next.tab || previous?.search != next.search;
    setState(() {
      _address = next;
      if (listChanged) _page = 0;
    });
    RecoveryDashboardAddress.lastVisit = next;
    final router = LocationQuery.ownedBy(context);
    if (router != null) LocationQuery.write(router, next.toQueryParameters());
    if (changed && ask) {
      context.read<RecoveryDashboardCubit>().ask(yearId, next.question);
    }
    if (listChanged) _loadStudents();
  }

  RecoveryStudentsQuery _studentsQuery(RecoveryDashboardAddress a) =>
      RecoveryStudentsQuery(
        question: a.question,
        tab: a.tab,
        search: a.search,
        page: _page,
      );

  void _loadStudents() {
    final yearId = _yearId;
    final address = _address;
    if (yearId == null || address == null) return;
    context.read<RecoveryStudentsCubit>().load(yearId, _studentsQuery(address));
  }

  Future<void> _refresh() async {
    final yearId = _yearId;
    final address = _address;
    if (yearId == null || address == null) return;
    await Future.wait([
      context.read<RecoveryDashboardCubit>().ask(yearId, address.question),
      context.read<RecoveryStudentsCubit>().load(
        yearId,
        _studentsQuery(address),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return TreasuryRefreshScope(
      onRefresh: _refresh,
      child: AppPageBackground(
        width: PageContentWidth.wide,
        child: BlocBuilder<AcademicYearContextBloc, AcademicYearContextState>(
          buildWhen: (p, c) => p.status != c.status || p.context != c.context,
          builder: (context, yearState) {
            final status = yearState.status;
            if (status == AcademicYearContextLoadStatus.loading ||
                status == AcademicYearContextLoadStatus.initial) {
              return const Padding(
                padding: EdgeInsets.symmetric(
                  vertical: AppDimensions.spacingXL,
                ),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final yearContext = yearState.context;
            if (status != AcademicYearContextLoadStatus.success ||
                yearContext == null) {
              return BootstrapContextError(
                onLogout: () =>
                    context.read<AuthBloc>().add(const AuthLogoutRequested()),
              );
            }
            final yearId = yearContext.academicYear.id;
            if (_yearId != yearId) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _start(yearId);
              });
            }
            return BlocListener<RecoveryCatalogCubit, RecoveryCatalogState>(
              listenWhen: (p, c) => p.status != c.status,
              listener: (_, catalog) => _onCatalog(catalog),
              child:
                  BlocListener<RecoveryDashboardCubit, RecoveryDashboardState>(
                    // La règle retombée côté serveur (mixte) : l'adresse suit.
                    listenWhen: (p, c) =>
                        c.question != null &&
                        _address != null &&
                        c.question != _address!.question &&
                        c.status != RecoveryLoadStatus.loading,
                    listener: (_, s) =>
                        _apply(_address!.withQuestion(s.question!), ask: false),
                    child: RecoveryDashboardBody(
                      academicYearId: yearId,
                      yearName: yearContext.academicYear.name,
                      groups: yearContext.schoolLevelGroups,
                      address: _address,
                      onAddressChanged: _apply,
                      onPageChanged: (page) {
                        setState(() => _page = page);
                        _loadStudents();
                      },
                      onRetry: _refresh,
                    ),
                  ),
            );
          },
        ),
      ),
    );
  }
}
