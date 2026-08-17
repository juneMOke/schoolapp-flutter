import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_holder.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_keys.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_repository.dart';
import 'package:school_app_flutter/core/offline/plan/sync_plan_state.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/data/sync/coordinator_payments_sync.dart';

/// Le seam paiements du grand-livre passe-t-il vraiment par le coordinateur, et
/// le plan gouverne-t-il vraiment ce qu'il tire ?
///
/// Ces tests montent un **vrai** [PullCoordinator] avec un vrai
/// [SyncPlanHolder] : un coordinateur simulé prouverait que la classe appelle
/// une méthode, pas que le plan décide. Or c'est exactement la question — ce
/// chemin échappait au plan, et le rebrancher en direct sur le repository
/// rouvrirait la porte sans qu'aucun test simulé ne bronche.
class _MockConnectivity extends Mock implements Connectivity {}

ConnectivityService _connectivity({required bool online}) {
  final mock = _MockConnectivity();
  when(() => mock.checkConnectivity()).thenAnswer(
    (_) async => [online ? ConnectivityResult.wifi : ConnectivityResult.none],
  );
  return ConnectivityService(mock);
}

/// Handler des paiements, à l'identique de celui que la DI enregistre : même
/// ressource, même exigence de droit.
class _PaymentsHandler implements PullHandler {
  _PaymentsHandler(this._outcome);

  final PullOutcome _outcome;
  int calls = 0;

  @override
  String get resource => FinancePullRepositoryImpl.paymentsResource;

  @override
  List<Perm> get requiredPermissions => const [Perm.financePaymentRead];

  @override
  bool get isBaseline => false;

  @override
  Future<PullOutcome> pull() async {
    calls++;
    return _outcome;
  }
}

class _FixedPlanRepository implements SyncPlanRepository {
  _FixedPlanRepository(this.state);
  final SyncPlanState state;

  @override
  Future<SyncPlanState> load() async => state;
  @override
  Future<SyncPlanState> loadCached() async => state;
  @override
  Future<SyncPlanState?> refreshFromNetwork() async => state;
}

SyncPlan _planWithKeys(List<String> keys) => SyncPlan(
  planVersion: 1,
  subject: 'uid-A',
  onAbsence: 'ignore',
  streams: [
    for (final key in keys)
      SyncPlanFlow(
        key: key,
        clientResource: resourcesOf(key),
        mode: SyncFlowMode.keyset,
        scope: SyncFlowScope.school,
        reason: const ['plan'],
        dependsOn: const [],
      ),
  ],
);

void main() {
  PullCoordinator build({
    required SyncPlanState plan,
    required _PaymentsHandler handler,
    List<String> permissions = const ['finance.payment.read'],
    bool online = true,
  }) {
    final holder = SyncPlanHolder(repository: _FixedPlanRepository(plan));
    addTearDown(holder.dispose);
    return PullCoordinator(
      connectivity: _connectivity(online: online),
      permissions: CurrentPermissions()..set(permissions),
      planHolder: holder,
    )..registerHandler(handler);
  }

  test(
    'un plan qui PORTE les paiements les tire, et l\'historique est déclaré à '
    'jour',
    () async {
      final handler = _PaymentsHandler(const PullOutcome.updated());
      final sync = CoordinatorPaymentsSync(
        build(
          plan: SyncPlanState.known(
            _planWithKeys(const [SyncPlanKeys.financePayments]),
          ),
          handler: handler,
        ),
      );

      expect(await sync(), isTrue);
      expect(handler.calls, 1);
    },
  );

  test(
    '304 vaut « à jour » — « rien n\'a changé » n\'est pas un échec',
    () async {
      final handler = _PaymentsHandler(const PullOutcome.notModified());
      final sync = CoordinatorPaymentsSync(
        build(
          plan: SyncPlanState.known(
            _planWithKeys(const [SyncPlanKeys.financePayments]),
          ),
          handler: handler,
        ),
      );

      expect(await sync(), isTrue);
      expect(handler.calls, 1);
    },
  );

  test(
    'LE TEST DE LA PORTE : un plan qui ne porte PAS les paiements ne les tire '
    'pas, et n\'autorise aucune fraîcheur',
    () async {
      // C'est le cas discriminant de tout ce fichier. Avant le correctif, ce
      // seam appelait `FinancePullRepository.syncPayments()` en direct : le
      // handler partait quoi que dise le plan. Un profil `finance.charge.read`
      // seul — dont le plan porte bien les créances mais PAS les paiements —
      // tirait donc un flux hors de son périmètre.
      final handler = _PaymentsHandler(const PullOutcome.updated());
      final sync = CoordinatorPaymentsSync(
        build(
          plan: SyncPlanState.known(
            _planWithKeys(const [SyncPlanKeys.financeStudentCharges]),
          ),
          handler: handler,
        ),
      );

      expect(await sync(), isFalse);
      expect(
        handler.calls,
        0,
        reason: 'le plan est l\'autorité : hors plan, rien ne part',
      );
    },
  );

  test('un plan VIDE ne tire rien non plus', () async {
    final handler = _PaymentsHandler(const PullOutcome.updated());
    final sync = CoordinatorPaymentsSync(
      build(
        plan: SyncPlanState.empty(_planWithKeys(const [])),
        handler: handler,
      ),
    );

    expect(await sync(), isFalse);
    expect(handler.calls, 0);
  });

  test('plan INCONNU : le filtre de droits reprend la main — sans le droit '
      'paiements, rien ne part', () async {
    final handler = _PaymentsHandler(const PullOutcome.updated());
    final sync = CoordinatorPaymentsSync(
      build(
        plan: const SyncPlanState.unknown(SyncPlanUnknownCause.notDeployed),
        handler: handler,
        permissions: const ['finance.charge.read'],
      ),
    );

    expect(await sync(), isFalse);
    expect(handler.calls, 0);
  });

  test(
    'plan INCONNU avec le droit : le mode dégradé tire, comme avant le lot',
    () async {
      final handler = _PaymentsHandler(const PullOutcome.updated());
      final sync = CoordinatorPaymentsSync(
        build(
          plan: const SyncPlanState.unknown(SyncPlanUnknownCause.notDeployed),
          handler: handler,
        ),
      );

      expect(await sync(), isTrue);
      expect(handler.calls, 1);
    },
  );

  test('un échec de cycle n\'autorise aucune fraîcheur', () async {
    final handler = _PaymentsHandler(const PullOutcome.error('boom'));
    final sync = CoordinatorPaymentsSync(
      build(
        plan: SyncPlanState.known(
          _planWithKeys(const [SyncPlanKeys.financePayments]),
        ),
        handler: handler,
      ),
    );

    expect(await sync(), isFalse);
    expect(handler.calls, 1);
  });

  test(
    'hors ligne : rien n\'est observé, donc rien n\'est déclaré à jour',
    () async {
      // ⚠️ Le refresher a déjà sa propre pré-garde radio, donc ce cas ne devrait
      // pas se produire. On le fige quand même : la valeur rendue ici commande
      // l\'estampille « à jour à HHhMM » sous les totaux, et l\'écran replie
      // l\'historique en « total payé ». Un `true` par défaut sur un rapport qui
      // n\'a RIEN observé ferait réencaisser un versement déjà reçu ailleurs.
      final handler = _PaymentsHandler(const PullOutcome.updated());
      final sync = CoordinatorPaymentsSync(
        build(
          plan: SyncPlanState.known(
            _planWithKeys(const [SyncPlanKeys.financePayments]),
          ),
          handler: handler,
          online: false,
        ),
      );

      expect(await sync(), isFalse);
      expect(handler.calls, 0);
    },
  );

  test('l\'ensemble demandé est réduit aux seuls paiements', () async {
    // Y ajouter les créances rejouerait un cycle de masse dans un chemin de
    // lecture borné à quelques secondes — le refresher vient de rafraîchir les
    // créances de CET élève par un point read scopé.
    expect(CoordinatorPaymentsSync.resources, {
      FinancePullRepositoryImpl.paymentsResource,
    });
  });
}
