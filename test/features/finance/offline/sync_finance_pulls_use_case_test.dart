import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/auth/current_permissions.dart';
import 'package:school_app_flutter/core/auth/permissions.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/pull_coordinator.dart';
import 'package:school_app_flutter/core/offline/pull_handler.dart';
import 'package:school_app_flutter/core/offline/session_credentials_probe.dart';
import 'package:school_app_flutter/features/enrollment/offline/data/repositories/enrollment_pull_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/data/repositories/finance_pull_repository_impl.dart';
import 'package:school_app_flutter/features/finance/offline/domain/usecases/sync_finance_pulls_use_case.dart';

/// Le use case a été replié sur `PullCoordinator.pullSubset` (ADR-015 F6). Il
/// portait une règle que rien d'autre n'avait — **créances KO ⇒ on ne tente même
/// pas les paiements** — et cette règle est la plus chère du dépôt : dans
/// l'autre sens, le caissier réencaisse.
///
/// Ces tests montent donc un coordinateur RÉEL avec des handlers factices : ce
/// qu'il faut prouver n'est pas « `pullSubset` a été appelé », c'est que la
/// garde **mord toujours sur ce chemin précis**. Elle vit désormais dans deux
/// pièces du socle qui ne se touchent que par la table d'alias
/// (`MoneyGradeEdge.blocking` et `PullCoordinator._isBlockedBy`, joints par
/// `planKeyOf`) : une clé mal orthographiée rouvrirait la porte en silence, et
/// aucun test d'ordre ne le verrait.
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
/// façon de distinguer « tenté et échoué » de « pas tenté du tout », qui est
/// exactement la distinction en jeu ici.
class _JournalHandler implements PullHandler {
  _JournalHandler(
    this.resource,
    this._journal,
    this.requiredPermissions, {
    this.fails = false,
  });

  @override
  final String resource;

  @override
  final List<Perm> requiredPermissions;

  @override
  bool get isBaseline => false;

  final List<String> _journal;
  final bool fails;

  @override
  Future<PullOutcome> pull() async {
    _journal.add(resource);
    return fails
        ? const PullOutcome.error('réseau coupé')
        : const PullOutcome.updated(upserted: 1);
  }
}

void main() {
  late List<String> journal;
  late _Connectivity connectivity;
  late _Credentials credentials;
  late CurrentPermissions permissions;

  const charges = FinancePullRepositoryImpl.chargesResource;
  const payments = FinancePullRepositoryImpl.paymentsResource;
  const enrollments = EnrollmentPullRepositoryImpl.deltaResource;

  setUp(() {
    journal = [];
    connectivity = _Connectivity(true);
    credentials = _Credentials(true);
    permissions = CurrentPermissions();
  });

  /// Registre monté dans l'ordre de la DI réelle : les flux Inscription, puis
  /// les créances, puis les paiements.
  SyncFinancePullsUseCase build({
    bool chargesFail = false,
    bool paymentsFail = false,
  }) {
    final coordinator =
        PullCoordinator(
            connectivity: connectivity,
            permissions: permissions,
            credentialsProbe: credentials,
          )
          ..registerHandler(
            _JournalHandler(enrollments, journal, const [Perm.enrollmentRead]),
          )
          ..registerHandler(
            _JournalHandler(charges, journal, const [
              Perm.financeChargeRead,
            ], fails: chargesFail),
          )
          ..registerHandler(
            _JournalHandler(payments, journal, const [
              Perm.financePaymentRead,
            ], fails: paymentsFail),
          );
    return SyncFinancePullsUseCase(coordinator);
  }

  test('ordre PORTEUR : les créances (vérité du grand-livre) sont tirées AVANT '
      'les paiements — et les flux voisins du registre ne sont pas '
      'emportés', () async {
    final report = await build()();

    expect(journal, [charges, payments]);
    expect(report.updated, 2);
    expect(report.failed, 0);
    expect(report.blocked, 0);
  });

  // LE test de ce lot. `verifyNever` n'existe pas ici : c'est le journal qui
  // prouve que rien n'est parti, ce qui est plus fort qu'un compteur — un
  // paiement inséré SYNCED par-dessus un `amount_paid_in_cents` périmé fait
  // afficher la créance IMPAYÉE, et le caissier RÉENCAISSE.
  test('DÉPENDANCE, pas simple ordre : créances KO → les paiements ne sont '
      'même pas tentés (les avancer sur un miroir périmé fait '
      'RÉENCAISSER)', () async {
    final report = await build(chargesFail: true)();

    expect(journal, [charges]);
    expect(
      journal,
      isNot(contains(payments)),
      reason:
          'Les paiements ne doivent pas être DEMANDÉS, pas seulement '
          'échouer : la garde MoneyGradeEdge.blocking a été perdue en route.',
    );
    expect(report.failed, 1);
    expect(report.blocked, 1);
    expect(report.succeeded(payments), isFalse);
    expect(report.isDegraded, isTrue);
  });

  // Le sens de panne est asymétrique, et c'est tout l'argument : dans CE sens,
  // le solde autoritaire compte déjà le paiement local, la créance s'affiche
  // sur-payée, le caissier refuse un encaissement. Friction, argent sauf, et ça
  // se résorbe seul. On poursuit donc.
  test('best-effort dans l\'autre sens : l\'échec des PAIEMENTS ne compte pas '
      'en abandon — le miroir des créances, lui, est bien à jour', () async {
    final report = await build(paymentsFail: true)();

    expect(journal, [charges, payments]);
    expect(report.failed, 1);
    expect(report.blocked, 0);
    expect(report.succeeded(charges), isTrue);
    expect(report.succeeded(payments), isFalse);
  });

  test('permission : sans finance.payment.read, les paiements sont sautés et '
      'les créances descendent quand même', () async {
    permissions.set(const ['finance.charge.read', 'enrollment.read']);

    final report = await build()();

    expect(journal, [charges]);
    expect(report.forbidden, 1);
    expect(report.updated, 1);
  });

  test('gate connectivité : hors-ligne, aucune des deux ressources n\'est '
      'appelée', () async {
    connectivity.online = false;

    final report = await build()();

    expect(journal, isEmpty);
    expect(report.offline, isTrue);
  });

  test('gate crédentiels : sans session authentifiable, aucune des deux '
      'ressources n\'est appelée', () async {
    credentials.usable = false;

    final report = await build()();

    expect(journal, isEmpty);
    expect(report.skipped, isTrue);
  });
}
