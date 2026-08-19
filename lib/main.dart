import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:school_app_flutter/core/components/status/sync_indicator.dart';
import 'package:school_app_flutter/core/components/status/sync_lifecycle_observer.dart';
import 'package:school_app_flutter/core/components/status/sync_status_cubit.dart';
import 'package:school_app_flutter/features/finance/offline/presentation/bloc/payment_anomalies_cubit.dart';
import 'package:school_app_flutter/features/finance/presentation/widgets/payment_anomaly_banner.dart';
import 'package:school_app_flutter/core/components/status/sync_status_state.dart';
import 'package:school_app_flutter/core/di/injection.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_cache_session_guard.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/local/pre_enrollments_school_guard.dart';
import 'package:school_app_flutter/features/documents/data/local/editique_document_cache.dart';
import 'package:school_app_flutter/core/theme/app_theme.dart';
import 'package:school_app_flutter/core/web/splash_loader.dart';
import 'package:school_app_flutter/features/academic_year/presentation/bloc/academic_year_context_bloc.dart';
import 'package:school_app_flutter/features/school/presentation/cubit/school_identity_cubit.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_event.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/auth_state.dart';
import 'package:school_app_flutter/features/auth/presentation/bloc/forgot_password_bloc.dart';
import 'package:school_app_flutter/features/auth/presentation/widgets/session_degradation_banner.dart';
import 'package:school_app_flutter/l10n/app_localizations.dart';
import 'package:school_app_flutter/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();
  runApp(const MyApp());
  // Web : retirer le pré-splash HTML une fois le 1er frame Flutter peint
  // (évite le trou bleu entre l'attache de la vue et le premier rendu).
  WidgetsBinding.instance.addPostFrameCallback((_) => removeWebSplashLoader());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.unknown,
  };
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final AcademicYearContextBloc _academicYearContextBloc;
  late final ForgotPasswordBloc _forgotPasswordBloc;
  late final SyncStatusCubit _syncStatusCubit;
  late final PaymentAnomaliesCubit _paymentAnomaliesCubit;
  late final SchoolIdentityCubit _schoolIdentityCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = getIt<AuthBloc>()..add(const AuthCheckRequested());
    // Contrairement à l'ex-bootstrap (lecture Hive spéculative avant même
    // l'auth), la résolution ne peut démarrer qu'une fois le schoolId connu
    // (`CurrentUserContext`, posé par l'auth) : rien à déclencher ici, le
    // redirect du router reste de toute façon bloqué sur `isAuthLoading`
    // jusqu'à la transition `authenticated` ci-dessous.
    _academicYearContextBloc = getIt<AcademicYearContextBloc>();
    _forgotPasswordBloc = getIt<ForgotPasswordBloc>();
    // Cubit global de synchro : instance unique app-lifetime, fournie à tout
    // l'arbre via `.value` (top bar + écrans write-path la lisent par contexte).
    _syncStatusCubit = getIt<SyncStatusCubit>();
    _paymentAnomaliesCubit = getIt<PaymentAnomaliesCubit>()..refresh();
    // Identité de l'établissement : rien à charger avant l'auth (le
    // schoolId vient de la session), la lecture est déclenchée par la
    // transition `authenticated` ci-dessous.
    _schoolIdentityCubit = getIt<SchoolIdentityCubit>();
    _router = AppRouter.createRouter(_authBloc, _academicYearContextBloc);
  }

  /// Balaie les fichiers du cache éditique que l'index ne désigne plus.
  ///
  /// Volontairement **muet et sans effet visible** : c'est de l'hygiène de
  /// disque, jamais une raison de retarder une ouverture de session ni
  /// d'afficher quoi que ce soit. Passe par le cache et non par le magasin,
  /// seul moyen d'être sûr qu'aucune écriture n'est en cours — un fichier tout
  /// juste scellé, ligne pas encore insérée, serait sinon pris pour un
  /// orphelin.
  Future<void> _reclaimEditiqueCacheOrphans() async {
    try {
      // D'ABORD ce qu'une ouverture de session décide du cache : un profil sans
      // droit ou une école qui a changé l'effacent entièrement (ADR-012 D-7,
      // RG-012-4/21). Réclamer des orphelins avant cette décision les aurait
      // épargnés le temps d'un cycle.
      await getIt<EditiqueCacheSessionGuard>().onSessionOpened();
      await getIt<EditiqueDocumentCache>().reclaimOrphans();
    } catch (_) {
      // Cache indisponible, plateforme absente : sans conséquence.
    }
  }

  /// Ce qu'une ouverture de session décide du vivier de préinscriptions.
  ///
  /// `ref_pre_enrollments` ne porte pas de colonne `school_id` : sur une
  /// tablette réaffectée, la recherche PRE continuait de proposer les candidats
  /// de l'établissement précédent. La garde efface le vivier ET rembobine le
  /// flux — cette table étant, depuis la bascule dure du seed vers le local, la
  /// seule source d'amorçage d'un brouillon, une purge sans rembobinage rendrait
  /// ses lignes définitivement inatteignables.
  ///
  /// Déclenché AVANT le cycle de pull ci-dessous : la garde ne fait que lire
  /// `sync_meta` et, le cas échéant, vider une table, quand le pull attend le
  /// réseau. L'ordre inverse ne serait pas faux pour autant — la purge
  /// rembobinant tout le flux, une page arrivée trop tôt est effacée avec son
  /// curseur, et redescend intégralement au cycle suivant.
  Future<void> _guardPreEnrollmentsSchool() async {
    try {
      await getIt<PreEnrollmentsSchoolGuard>().onSessionOpened();
    } catch (_) {
      // Base indisponible : sans conséquence sur la session.
    }
  }

  @override
  void dispose() {
    _academicYearContextBloc.close();
    _forgotPasswordBloc.close();
    _authBloc.close();
    _syncStatusCubit.close();
    _paymentAnomaliesCubit.close();
    _schoolIdentityCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<AcademicYearContextBloc>.value(
          value: _academicYearContextBloc,
        ),
        BlocProvider<ForgotPasswordBloc>.value(value: _forgotPasswordBloc),
        BlocProvider<SyncStatusCubit>.value(value: _syncStatusCubit),
        // Anomalies d'encaissement (ADR-012 D-5, amendé). La relecture est
        // pilotée par le cubit lui-même, abonné à la FIN de chaque flush :
        // c'est la transaction d'ACK qui écrit l'anomalie, et aucune transition
        // de connectivité n'encadre correctement ce moment.
        BlocProvider<PaymentAnomaliesCubit>.value(
          value: _paymentAnomaliesCubit,
        ),
        BlocProvider<SchoolIdentityCubit>.value(value: _schoolIdentityCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == AuthStatus.authenticated) {
                // Un seul événement, en ligne comme hors-ligne (ADR-010
                // D-01/D-02) : le repository lit d'abord le référentiel local
                // et ne tente un pull réseau que s'il est absent — jamais de
                // fetch distant voué à l'échec en offline.
                _academicYearContextBloc.add(
                  const AcademicYearContextRequested(),
                );
                // AVANT le cycle : une école qui a changé efface le vivier de
                // préinscriptions et rembobine son flux, faute de quoi le
                // nouveau guichet chercherait dans les candidats de l'ancien
                // (`ref_pre_enrollments` n'a pas de colonne `school_id`).
                unawaited(_guardPreEnrollmentsSchool());
                // Jetons frais ou repli offline : dans les deux cas, pousse
                // l'outbox en attente et recalcule la pastille de synchro
                // (D-05, réconciliation silencieuse au retour réseau si
                // offline) — puis TIRE (ADR-015 F0).
                //
                // Le cycle de pull n'avait qu'un seul déclencheur, la
                // transition hors-ligne → en ligne : une tablette allumée le
                // matin dans une école déjà couverte en Wi-Fi n'exécutait
                // aucun cycle de coordinateur de toute la journée. En
                // `unawaited` : la porte de navigation ne dépend que du
                // contexte académique demandé juste au-dessus, et rien de
                // réseau ne doit la retarder.
                // Arme aussi le battement de la file (lot 2) : la cadence est
                // portée par `syncOnLogin` lui-même, pour qu'il n'y ait qu'un
                // seul fil de session à ne pas oublier ici.
                unawaited(_syncStatusCubit.syncOnLogin());
                // Entretien du cache de restitution éditique (ADR-012 D-7) :
                // réclame les fichiers chiffrés qu'aucune ligne d'index ne
                // désigne plus. Une purge d'école interrompue en laisse — des
                // octets invisibles à la comptabilité de budget, que plus rien
                // ne réclamerait. Ici plutôt qu'au démarrage : c'est le premier
                // instant où l'identité est connue, donc le seul endroit où la
                // garde de rôle du lot L3.6 pourra s'interposer sans que ce
                // crochet ait à être déplacé. Ni clé ni répertoire ne sont
                // touchés par ce balayage.
                unawaited(_reclaimEditiqueCacheOrphans());
                // Nom et ville de l'école : le référentiel local peut déjà les
                // porter (session rouverte hors ligne) ou être pullé dans la
                // foulée par le contexte académique — d'où la relecture au
                // retour réseau plus bas.
                unawaited(_schoolIdentityCubit.load());
                return;
              }

              if (state.status == AuthStatus.unauthenticated) {
                _academicYearContextBloc.add(
                  const AcademicYearContextResetRequested(),
                );
                // Sans cela, une reconnexion sur une autre école garderait le
                // nom de la précédente le temps du rechargement.
                _schoolIdentityCubit.clear();
                // Coupe le battement : sans jetons, chaque tic n'interrogerait
                // que la sonde de crédentiels d'une session qui n'existe plus.
                _syncStatusCubit.onSessionClosed();
              }
            },
          ),
          // Session rejetée côté serveur (401/403) pendant le pull référentiel
          // → logout. Le couplage contexte académique→auth passe par
          // main.dart (sens unique, comme auth→contexte académique).
          BlocListener<AcademicYearContextBloc, AcademicYearContextState>(
            listenWhen: (previous, current) =>
                !previous.sessionExpired && current.sessionExpired,
            listener: (context, state) =>
                _authBloc.add(const AuthLogoutRequested()),
          ),
          // Retour réseau après une période hors-ligne : re-résout le contexte
          // académique (le référentiel a pu changer pendant la coupure — le
          // PullCoordinator le rafraîchit déjà en local, mais l'instance
          // globale de ce Bloc ne le relirait pas d'elle-même).
          BlocListener<SyncStatusCubit, SyncStatusState>(
            listenWhen: (previous, current) =>
                previous.status == SyncStatus.offline &&
                current.status != SyncStatus.offline,
            listener: (context, state) {
              _academicYearContextBloc.add(
                const AcademicYearContextRequested(),
              );
              unawaited(_schoolIdentityCubit.load());
            },
          ),
        ],
        // Troisième déclencheur global de la boucle de synchro (les deux
        // autres : ouverture de session et retour réseau). Rien n'est
        // périodique dans cette boucle — un backoff ou une dépendance qui
        // repousse une entrée ne fait que la rendre *éligible*, personne ne la
        // reprend — et une tablette posée sur le Wi-Fi de l'école ne voit
        // jamais de transition réseau. La reprise au premier plan est le seul
        // signal restant qui arrive plusieurs fois par jour.
        //
        // Gardé sur la session : sur l'écran de connexion il n'y a ni jetons ni
        // file à pousser. Le cubit s'en garderait de lui-même (sonde de
        // crédentiels), mais un cycle qu'on sait vide ne mérite pas d'être
        // lancé. L'anti-rafale, elle, est dans le cubit — c'est sa politique,
        // pas celle de la racine.
        child: SyncLifecycleObserver(
          onResume: () {
            // Le battement d'abord : il ne dépend pas de la session (le cubit
            // réconcilie les deux conditions lui-même) et un cycle de reprise
            // qui échoue ne doit pas laisser la file sans relance périodique.
            _syncStatusCubit.onForeground();
            if (_authBloc.state.status != AuthStatus.authenticated) return;
            unawaited(_syncStatusCubit.syncOnResume());
          },
          onPause: _syncStatusCubit.onBackground,
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            scrollBehavior: const AppScrollBehavior(),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            locale: const Locale('fr'),
            supportedLocales: AppLocalizations.supportedLocales,
            title: 'ETEELO CONNECT',
            theme: AppTheme.light,
            routerConfig: _router,
            // Bandeau global au-dessus de toutes les routes : dégradation de
            // session offline (ADR-010 D-08). Le bandeau « données en cache »
            // de l'ex-bootstrap est retiré (plus de distinction local/distant
            // séparée à ce niveau) — le statut réseau global reste signalé par
            // le `SyncIndicator` de la top bar.
            // Deux bandeaux globaux, empilés du plus contraignant au moins :
            // l'anomalie d'argent (non dismissible, ADR-012) prime sur la
            // dégradation de session (informative, ADR-010).
            builder: (context, child) => PaymentAnomalyBanner(
              child: SessionDegradationBanner(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
