import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/desktop_update_repository.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/last_run_version_store.dart';
import 'package:school_app_flutter/features/desktop_update/presentation/cubit/desktop_update_state.dart';

/// Pousse l'outbox puis rend le nombre d'opérations qui restent.
typedef PendingOperationsProbe = Future<int> Function();

/// Mise à jour du poste de bureau : vérifie au démarrage puis à chaque top de
/// [ticks] (en ligne seulement : un échec de lecture ne change rien), propose,
/// et après l'accord pousse l'outbox, télécharge, contrôle, installe, ferme.
class DesktopUpdateCubit extends Cubit<DesktopUpdateState> {
  final DesktopUpdateRepository _repository;
  final AppVersion? _installed;
  final PendingOperationsProbe _pendingOperations;
  final LastRunVersionStore _lastRun;
  final Stream<void> _ticks;
  final void Function() _exitApp;

  StreamSubscription<void>? _tickSubscription;
  DownloadCancellation? _cancellation;
  bool _checking = false;

  DesktopUpdateCubit({
    required DesktopUpdateRepository repository,
    required AppVersion? installed,
    required PendingOperationsProbe pendingOperations,
    required LastRunVersionStore lastRun,
    required Stream<void> ticks,
    required void Function() exitApp,
  }) : _repository = repository,
       _installed = installed,
       _pendingOperations = pendingOperations,
       _lastRun = lastRun,
       _ticks = ticks,
       _exitApp = exitApp,
       super(const DesktopUpdateState());

  Future<void> start() async {
    final installed = _installed;
    // Version illisible : on ne saurait rien comparer, on ne propose rien.
    if (installed == null) return;
    await _announceIfJustUpdated(installed);
    if (isClosed) return;
    _tickSubscription = _ticks.listen((_) => unawaited(check()));
    await check();
  }

  /// Relit la dernière version. Sans effet pendant un geste en cours.
  Future<void> check() async {
    final installed = _installed;
    if (installed == null || _checking || state.busy || isClosed) return;
    if (state.status == DesktopUpdateStatus.confirmPending ||
        state.status == DesktopUpdateStatus.failed) {
      return;
    }
    _checking = true;
    try {
      final result = await _repository.fetchOffer(installed);
      if (isClosed) return;
      result.fold((_) {}, (offer) {
        if (offer == null) {
          emit(
            const DesktopUpdateState().copyWith(
              justUpdatedTo: state.justUpdatedTo,
            ),
          );
          return;
        }
        final sameRelease = state.offer?.release == offer.release;
        emit(
          state.copyWith(
            status: DesktopUpdateStatus.available,
            offer: offer,
            // Une version encore plus récente rouvre la question.
            dismissed: sameRelease && state.dismissed,
          ),
        );
      });
    } finally {
      _checking = false;
    }
  }

  /// « Plus tard » — refusé quand la mise à jour est obligatoire.
  void later() {
    if (state.mandatory || state.status != DesktopUpdateStatus.available) {
      return;
    }
    emit(state.copyWith(dismissed: true, requested: false));
  }

  /// Rouvre la fenêtre (pastille du menu du compte).
  void reopen() {
    if (!state.hasOffer) return;
    emit(state.copyWith(dismissed: false, requested: true));
  }

  /// « Mettre à jour » : l'outbox d'abord.
  Future<void> update() async {
    if (!state.hasOffer || state.busy) return;
    emit(state.copyWith(status: DesktopUpdateStatus.preparing, error: null));
    final pending = await _pendingOperations();
    if (isClosed) return;
    if (pending > 0) {
      emit(
        state.copyWith(
          status: DesktopUpdateStatus.confirmPending,
          pendingOperations: pending,
        ),
      );
      return;
    }
    await _downloadAndInstall();
  }

  /// Continuer malgré les opérations en attente (elles restent dans la base).
  Future<void> continueDespitePending() async {
    if (state.status != DesktopUpdateStatus.confirmPending) return;
    await _downloadAndInstall();
  }

  /// Annule le téléchargement, ou renonce depuis la confirmation ou l'échec.
  void cancel() {
    if (state.status == DesktopUpdateStatus.downloading) {
      _cancellation?.cancel();
      return;
    }
    if (state.status == DesktopUpdateStatus.confirmPending ||
        state.status == DesktopUpdateStatus.failed) {
      emit(
        state.copyWith(
          status: DesktopUpdateStatus.available,
          error: null,
          dismissed: !state.mandatory,
          requested: false,
        ),
      );
    }
  }

  /// L'annonce « Mis à jour » a été montrée.
  void acknowledgeJustUpdated() {
    if (state.justUpdatedTo == null) return;
    emit(state.copyWith(justUpdatedTo: null));
  }

  Future<void> _downloadAndInstall() async {
    final offer = state.offer;
    if (offer == null) return;
    final cancellation = _cancellation = DownloadCancellation();
    emit(state.copyWith(status: DesktopUpdateStatus.downloading, progress: 0));
    final downloaded = await _repository.download(
      offer.release,
      cancellation: cancellation,
      onProgress: (received, total) {
        if (isClosed || state.status != DesktopUpdateStatus.downloading) return;
        final value = total <= 0 ? 0.0 : (received / total).clamp(0.0, 1.0);
        // Un rendu par point de pourcentage, pas par paquet reçu.
        if ((value - state.progress).abs() >= 0.01 || value == 1.0) {
          emit(state.copyWith(progress: value));
        }
      },
    );
    _cancellation = null;
    if (isClosed) return;
    await downloaded.fold(
      (failure) async {
        if (failure is DownloadCancelledFailure) {
          emit(
            state.copyWith(status: DesktopUpdateStatus.available, progress: 0),
          );
          return;
        }
        _fail(failure);
      },
      (installer) async {
        emit(state.copyWith(status: DesktopUpdateStatus.installing));
        final installed = await _repository.install(installer);
        if (isClosed) return;
        installed.fold(_fail, (_) => _exitApp());
      },
    );
  }

  void _fail(Failure failure) => emit(
    state.copyWith(
      status: DesktopUpdateStatus.failed,
      error: switch (failure) {
        NetworkFailure() ||
        UncertainOutcomeFailure() ||
        TooManyRequestsFailure() ||
        ServerFailure() => DesktopUpdateError.network,
        IntegrityFailure() => DesktopUpdateError.integrity,
        InstallFailure() => DesktopUpdateError.install,
        StorageFailure() => DesktopUpdateError.storage,
        _ => DesktopUpdateError.unknown,
      },
    ),
  );

  Future<void> _announceIfJustUpdated(AppVersion installed) async {
    try {
      final previous = AppVersion.tryParseStrict(await _lastRun.read());
      if (previous != null && installed > previous && !isClosed) {
        emit(state.copyWith(justUpdatedTo: installed));
      }
      if (previous != installed) await _lastRun.write('$installed');
    } catch (_) {
      // Le trousseau indisponible ne doit rien empêcher : pas d'annonce.
    }
  }

  @override
  Future<void> close() async {
    _cancellation?.cancel();
    await _tickSubscription?.cancel();
    return super.close();
  }
}
