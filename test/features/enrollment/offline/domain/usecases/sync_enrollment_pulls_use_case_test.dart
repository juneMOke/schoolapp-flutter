import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_pull_repository_impl.dart';
import 'package:school_app_flutter/features/enrollment/offline/domain/usecases/sync_enrollment_pulls_use_case.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';

/// Le use case a été replié sur `PullCoordinator.pullSubset` (ADR-015 F6) : il
/// ne porte plus ni garde, ni ordre, ni permission — seulement **la liste des
/// ressources dont ces trois écrans ont besoin**.
///
/// Les tests montent donc un coordinateur RÉEL avec des handlers factices,
/// plutôt qu'un double du coordinateur : ce qu'on veut prouver n'est pas
/// « `pullSubset` a été appelé », c'est ce qui **sort** de ce chemin — les cinq
/// bonnes ressources, dans l'ordre du registre, et ce que le filtre de
/// permission en fait maintenant.
///
/// Les gardes elles-mêmes (connectivité, crédentiels, isolation, diffusion) sont
/// couvertes par `test/core/offline/pull_coordinator_test.dart` ; on ne vérifie
/// ici que leur **application à ce chemin**, qui les contournait auparavant.
class _Connectivity implements ConnectivityService {
  _Connectivity(this.online);

  bool online;

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onStatusChange => const Stream<bool>.empty();
}

class _Credentials implements SessionCredentialsProbe {
  _Credentials(this.usable);

  bool usable;

  @override
  Future<bool> canAuthenticate() async => usable;
}

/// Handler factice qui inscrit sa ressource dans un journal partagé — seule
/// façon d'observer l'ordre RÉEL d'exécution.
class _JournalHandler implements PullHandler {
  _JournalHandler(
    this.resource,
    this._journal, {
    this.requiredPermissions = const [Perm.enrollmentRead],
    this.isBaseline = false,
  });

  @override
  final String resource;

  @override
  final List<Perm> requiredPermissions;

  @override
  final bool isBaseline;

  final List<String> _journal;

  @override
  Future<PullOutcome> pull() async {
    _journal.add(resource);
    return const PullOutcome.updated(upserted: 1);
  }
}

void main() {
  late List<String> journal;
  late _Connectivity connectivity;
  late _Credentials credentials;
  late CurrentPermissions permissions;

  const referential = EnrollmentPullRepositoryImpl.referentialResource;
  const cohort = EnrollmentPullRepositoryImpl.cohortResource;
  const preEnrollments = EnrollmentPullRepositoryImpl.preEnrollmentsResource;
  const snapshots = EnrollmentPullRepositoryImpl.snapshotsResource;
  const delta = EnrollmentPullRepositoryImpl.deltaResource;

  setUp(() {
    journal = [];
    connectivity = _Connectivity(true);
    credentials = _Credentials(true);
    permissions = CurrentPermissions();
  });

  PullCoordinator coordinatorWith(List<String> registrationOrder) {
    final coordinator = PullCoordinator(
      connectivity: connectivity,
      permissions: permissions,
      credentialsProbe: credentials,
    );
    for (final resource in registrationOrder) {
      coordinator.registerHandler(
        _JournalHandler(
          resource,
          journal,
          // Le référentiel est le SEUL flux socle du dépôt : il échappe au
          // filtre de permission, et un test plus bas en dépend.
          isBaseline: resource == referential,
          requiredPermissions: resource == referential
              ? const [Perm.schoolRead]
              : const [Perm.enrollmentRead],
        ),
      );
    }
    return coordinator;
  }

  /// L'ordre d'enregistrement réel de la DI (`registerEnrollmentFinanceOffline`),
  /// verrouillé par `test/core/di/offline_pull_registration_order_test.dart`.
  const diOrder = [
    referential,
    cohort,
    preEnrollments,
    snapshots,
    delta,
    FinancePullRepositoryImpl.chargesResource,
    FinancePullRepositoryImpl.paymentsResource,
  ];

  test('les cinq ressources Inscription sont tirées, et elles seules — les '
      'flux voisins du même registre ne sont pas emportés', () async {
    final useCase = SyncEnrollmentPullsUseCase(coordinatorWith(diOrder));

    final report = await useCase();

    expect(journal, [referential, cohort, preEnrollments, snapshots, delta]);
    expect(report.updated, 5);
    expect(report.failed, 0);
    expect(report.forbidden, 0);
    expect(report.succeeded(delta), isTrue);
  });

  // L'arête la plus silencieuse du module : le delta ne fait qu'UPDATE des
  // lignes que seul l'hydratant INSERT. Inversés, le delta consomme son backlog
  // sans rien à mettre à jour et le curseur avance sur des dossiers que plus
  // rien ne redemandera — muets, sans la moindre erreur.
  test('l\'hydratant (snapshots) précède le delta', () async {
    final useCase = SyncEnrollmentPullsUseCase(coordinatorWith(diOrder));

    await useCase();

    expect(journal.indexOf(snapshots), lessThan(journal.indexOf(delta)));
  });

  // Ce test dit OÙ vit l'invariant d'ordre depuis le repli : dans la DI, pas
  // ici. Le use case ne donne qu'un ENSEMBLE — un `Set` littéral n'a pas
  // d'ordre porteur — et le coordinateur itère son registre. Un registre
  // permuté produit donc un ordre permuté : preuve que réordonner les accolades
  // du use case ne protégerait rien, et que le verrou est bien
  // `offline_pull_registration_order_test`.
  test('l\'ordre suit le REGISTRE, jamais les accolades du use case', () async {
    final useCase = SyncEnrollmentPullsUseCase(
      coordinatorWith(const [delta, snapshots, referential]),
    );

    await useCase();

    expect(journal, [delta, snapshots, referential]);
  });

  // La conséquence du repli qu'on ne retrouverait jamais six mois plus tard :
  // la Facturation et les Documents tiraient ces cinq flux SANS aucun filtre.
  test('permission : sans enrollment.read, seul le socle (référentiel) '
      'descend — les quatre autres comptent en forbidden', () async {
    permissions.set(const ['finance.charge.read']);
    final useCase = SyncEnrollmentPullsUseCase(coordinatorWith(diOrder));

    final report = await useCase();

    expect(journal, [referential]);
    expect(report.forbidden, 4);
    expect(report.updated, 1);
    expect(report.isDegraded, isTrue);
  });

  // Le référentiel porte la porte de navigation : sauté faute de droit, la
  // tablette reste sur l'écran d'amorçage sans autre issue que la déconnexion.
  test('permission : un ensemble VIDE ne coupe pas le socle', () async {
    permissions.set(const <String>[]);
    final useCase = SyncEnrollmentPullsUseCase(coordinatorWith(diOrder));

    final report = await useCase();

    expect(journal, [referential]);
    expect(report.forbidden, 4);
  });

  // Trois états, pas deux : `null` = ensemble inconnu (amorçage), et filtrer
  // dessus couperait toute la synchro sur un simple trou d'alimentation.
  test('permission : ensemble INCONNU (null) ne filtre rien', () async {
    final useCase = SyncEnrollmentPullsUseCase(coordinatorWith(diOrder));

    await useCase();

    expect(journal, hasLength(5));
  });

  test('gate connectivité : hors-ligne, aucune des cinq ressources n\'est '
      'appelée (aucune requête HTTP émise)', () async {
    connectivity.online = false;
    final useCase = SyncEnrollmentPullsUseCase(coordinatorWith(diOrder));

    final report = await useCase();

    expect(journal, isEmpty);
    expect(report.offline, isTrue);
  });

  test('gate crédentiels : sans session authentifiable, aucune des cinq '
      'ressources n\'est appelée', () async {
    credentials.usable = false;
    final useCase = SyncEnrollmentPullsUseCase(coordinatorWith(diOrder));

    final report = await useCase();

    expect(journal, isEmpty);
    expect(report.skipped, isTrue);
  });
}
