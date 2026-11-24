import 'dart:async';

import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:flutter_test/flutter_test.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/desktop_release.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/desktop_update_repository.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/last_run_version_store.dart';
import 'package:school_app_flutter/features/desktop_update/presentation/cubit/desktop_update_cubit.dart';
import 'package:school_app_flutter/features/desktop_update/presentation/cubit/desktop_update_state.dart';

import '../fixtures.dart';

class _Repo implements DesktopUpdateRepository {
  Either<Failure, DesktopUpdateOffer?> offerResult = Right(offer());
  Completer<Either<Failure, DesktopUpdateOffer?>>? pendingFetch;
  Either<Failure, VerifiedInstaller>? downloadResult;
  Completer<Either<Failure, VerifiedInstaller>>? pendingDownload;
  Either<Failure, bool> installResult = const Right(true);
  int fetches = 0, downloads = 0, installs = 0;
  DownloadCancellation? lastCancellation;

  @override
  Future<Either<Failure, DesktopUpdateOffer?>> fetchOffer(
    AppVersion installed,
  ) async {
    fetches++;
    if (pendingFetch != null) return pendingFetch!.future;
    return offerResult;
  }

  @override
  Future<Either<Failure, VerifiedInstaller>> download(
    DesktopRelease release, {
    void Function(int received, int total)? onProgress,
    DownloadCancellation? cancellation,
  }) {
    downloads++;
    lastCancellation = cancellation;
    onProgress?.call(50, 100);
    if (pendingDownload != null) return pendingDownload!.future;
    return Future.value(
      downloadResult ?? Right(VerifiedInstaller(path: '/x', release: release)),
    );
  }

  @override
  Future<Either<Failure, bool>> install(VerifiedInstaller installer) async {
    installs++;
    return installResult;
  }
}

class _Store implements LastRunVersionStore {
  String? value;
  _Store([this.value]);

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String version) async => value = version;
}

void main() {
  late _Repo repo;
  late _Store store;
  late StreamController<void> ticks;
  late int pending;
  Object? probeError;
  late int exits;

  setUp(() {
    repo = _Repo();
    store = _Store('1.8.0');
    ticks = StreamController<void>.broadcast();
    pending = 0;
    probeError = null;
    exits = 0;
  });

  tearDown(() => ticks.close());

  DesktopUpdateCubit cubit({
    AppVersion? installed = const AppVersion(1, 8, 0),
  }) => DesktopUpdateCubit(
    repository: repo,
    installed: installed,
    pendingOperations: () async {
      if (probeError != null) throw probeError!;
      return pending;
    },
    lastRun: store,
    ticks: ticks.stream,
    exitApp: () => exits++,
  );

  test(
    'au démarrage : une version est proposée, la fenêtre est voulue',
    () async {
      final c = cubit();
      await c.start();
      expect(c.state.status, DesktopUpdateStatus.available);
      expect(c.state.wantsDialog, isTrue);
      await c.close();
    },
  );

  test('version illisible : rien n’est demandé au back', () async {
    final c = cubit(installed: null);
    await c.start();
    expect(repo.fetches, 0);
    await c.close();
  });

  test(
    '« Plus tard » ferme la fenêtre ; la même version ne la rouvre pas',
    () async {
      final c = cubit();
      await c.start();
      c.later();
      expect(c.state.wantsDialog, isFalse);
      expect(c.state.hasOffer, isTrue);
      await c.check();
      expect(c.state.wantsDialog, isFalse);
      c.reopen();
      expect(c.state.wantsDialog, isTrue);
      expect(c.state.requested, isTrue);
      await c.close();
    },
  );

  test('une version encore plus récente rouvre la question', () async {
    final c = cubit();
    await c.start();
    c.later();
    repo.offerResult = Right(
      offer(of: release(version: const AppVersion(1, 9, 1))),
    );
    await c.check();
    expect(c.state.wantsDialog, isTrue);
    await c.close();
  });

  test('obligatoire : « Plus tard » est sans effet', () async {
    repo.offerResult = Right(offer(minimum: const AppVersion(1, 9, 0)));
    final c = cubit();
    await c.start();
    c.later();
    expect(c.state.wantsDialog, isTrue);
    expect(c.state.mandatory, isTrue);
    await c.close();
  });

  test('un échec de lecture ne retire pas l’offre connue', () async {
    final c = cubit();
    await c.start();
    repo.offerResult = const Left(NetworkFailure());
    await c.check();
    expect(c.state.status, DesktopUpdateStatus.available);
    await c.close();
  });

  test('outbox vide : télécharge, installe, ferme l’application', () async {
    final c = cubit();
    await c.start();
    await c.update();
    expect(repo.downloads, 1);
    expect(repo.installs, 1);
    expect(exits, 1);
    expect(c.state.status, DesktopUpdateStatus.installing);
    await c.close();
  });

  test(
    'opérations en attente : confirmation d’abord, rien n’est téléchargé',
    () async {
      pending = 3;
      final c = cubit();
      await c.start();
      await c.update();
      expect(c.state.status, DesktopUpdateStatus.confirmPending);
      expect(c.state.pendingOperations, 3);
      expect(repo.downloads, 0);
      await c.continueDespitePending();
      expect(repo.installs, 1);
      expect(exits, 1);
      await c.close();
    },
  );

  test(
    '« Annuler » à la confirmation : retour à l’offre, fenêtre fermée',
    () async {
      pending = 1;
      final c = cubit();
      await c.start();
      await c.update();
      c.cancel();
      expect(c.state.status, DesktopUpdateStatus.available);
      expect(c.state.wantsDialog, isFalse);
      expect(repo.downloads, 0);
      await c.close();
    },
  );

  test('fichier corrompu : échec « intégrité », pas d’installation', () async {
    repo.downloadResult = const Left(IntegrityFailure());
    final c = cubit();
    await c.start();
    await c.update();
    expect(c.state.status, DesktopUpdateStatus.failed);
    expect(c.state.error, DesktopUpdateError.integrity);
    expect(repo.installs, 0);
    expect(exits, 0);
    await c.close();
  });

  test('installateur en échec : l’application reste ouverte', () async {
    repo.installResult = const Left(InstallFailure('x'));
    final c = cubit();
    await c.start();
    await c.update();
    expect(c.state.error, DesktopUpdateError.install);
    expect(exits, 0);
    await c.close();
  });

  test('annulation pendant le téléchargement : retour à l’offre', () async {
    repo.pendingDownload = Completer();
    final c = cubit();
    await c.start();
    final updating = c.update();
    await Future<void>.delayed(Duration.zero);
    expect(c.state.status, DesktopUpdateStatus.downloading);
    expect(c.state.progress, 0.5);
    c.cancel();
    expect(repo.lastCancellation!.isCancelled, isTrue);
    repo.pendingDownload!.complete(const Left(DownloadCancelledFailure()));
    await updating;
    expect(c.state.status, DesktopUpdateStatus.available);
    expect(repo.installs, 0);
    await c.close();
  });

  test('aucune vérification pendant un téléchargement', () async {
    repo.pendingDownload = Completer();
    final c = cubit();
    await c.start();
    final updating = c.update();
    await Future<void>.delayed(Duration.zero);
    await c.check();
    expect(repo.fetches, 1);
    repo.pendingDownload!.complete(const Left(DownloadCancelledFailure()));
    await updating;
    await c.close();
  });

  test('chaque top relit la dernière version', () async {
    final c = cubit();
    await c.start();
    ticks.add(null);
    await Future<void>.delayed(Duration.zero);
    expect(repo.fetches, 2);
    await c.close();
  });

  test(
    'premier lancement d’une version plus haute : annoncé une fois',
    () async {
      store.value = '1.7.0';
      final c = cubit();
      await c.start();
      expect(c.state.justUpdatedTo, const AppVersion(1, 8, 0));
      // Pas encore montrée : rien n'est mémorisé.
      expect(store.value, '1.7.0');
      c.acknowledgeJustUpdated();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.justUpdatedTo, isNull);
      expect(store.value, '1.8.0');
      await c.close();
    },
  );

  test('premier lancement tout court : pas d’annonce', () async {
    store.value = null;
    final c = cubit();
    await c.start();
    expect(c.state.justUpdatedTo, isNull);
    expect(store.value, '1.8.0');
    await c.close();
  });

  test(
    'Windows : l’installateur ferme lui-même ; l’application attend',
    () async {
      repo.installResult = const Right(false);
      final c = cubit();
      await c.start();
      await c.update();
      expect(c.state.status, DesktopUpdateStatus.waitingForInstaller);
      expect(exits, 0);
      // Élévation refusée : on peut refermer la fenêtre.
      c.cancel();
      expect(c.state.status, DesktopUpdateStatus.available);
      expect(c.state.wantsDialog, isFalse);
      await c.close();
    },
  );

  test(
    'une lecture en vol ne recouvre pas un téléchargement commencé',
    () async {
      final c = cubit();
      await c.start();
      repo.pendingFetch = Completer();
      final checking = c.check();
      repo.pendingDownload = Completer();
      final updating = c.update();
      await Future<void>.delayed(Duration.zero);
      expect(c.state.status, DesktopUpdateStatus.downloading);
      // La version disparaît côté back pendant le téléchargement.
      repo.pendingFetch!.complete(const Right(null));
      await checking;
      expect(c.state.status, DesktopUpdateStatus.downloading);
      expect(c.state.wantsDialog, isTrue);
      repo.pendingDownload!.complete(const Left(DownloadCancelledFailure()));
      await updating;
      await c.close();
    },
  );

  test('file illisible : on demande, on ne fige pas', () async {
    probeError = StateError('aucune école ouverte');
    final c = cubit();
    await c.start();
    await c.update();
    expect(c.state.status, DesktopUpdateStatus.confirmPending);
    expect(c.state.pendingOperations, unknownPendingOperations);
    await c.close();
  });

  test(
    'annulé pendant le contrôle de l’empreinte : rien n’est installé',
    () async {
      repo.pendingDownload = Completer();
      final c = cubit();
      await c.start();
      final updating = c.update();
      await Future<void>.delayed(Duration.zero);
      c.cancel();
      repo.pendingDownload!.complete(
        Right(VerifiedInstaller(path: '/x', release: release())),
      );
      await updating;
      expect(repo.installs, 0);
      expect(c.state.status, DesktopUpdateStatus.available);
      await c.close();
    },
  );

  test('fenêtre fermée : la demande du menu est servie', () async {
    final c = cubit();
    await c.start();
    c.later();
    c.reopen();
    expect(c.state.requested, isTrue);
    c.dialogClosed();
    expect(c.state.requested, isFalse);
    await c.close();
  });
}
