import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:path_provider/path_provider.dart';
import 'package:school_app_flutter/core/config/env_config.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/core/network/dio_client.dart';
import 'package:school_app_flutter/core/offline/connectivity_service.dart';
import 'package:school_app_flutter/core/offline/outbox_dao.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_installer.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_release_api.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_release_verifier.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_update_downloader.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_update_log.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_update_repository_impl.dart';
import 'package:school_app_flutter/features/desktop_update/data/installer_transfer.dart';
import 'package:school_app_flutter/features/desktop_update/data/secure_last_run_version_store.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/desktop_release.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/desktop_update_repository.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/last_run_version_store.dart';
import 'package:school_app_flutter/features/desktop_update/presentation/cubit/desktop_update_cubit.dart';

/// Ce qu'il faut savoir du poste pour se mettre à jour : sa plateforme et sa
/// version. `null` hors d'un poste de bureau livré (tablette, web, `dev`,
/// build de débogage, version illisible, aucune clé de signature).
class DesktopUpdateContext {
  final DesktopPlatform platform;
  final AppVersion installed;

  const DesktopUpdateContext({required this.platform, required this.installed});

  static DesktopUpdateContext? resolve({
    required EnvConfig env,
    required String? packageVersion,
  }) {
    if (kIsWeb || !kReleaseMode || env.isDevelopment) return null;
    final keys = AppConstants.desktopUpdatePublicKeys[env.environment.label];
    if (keys == null || keys.isEmpty) return null;
    final platform = switch (defaultTargetPlatform) {
      TargetPlatform.windows => DesktopPlatform.windows,
      TargetPlatform.linux => DesktopPlatform.linux,
      _ => null,
    };
    final installed = AppVersion.tryParse(packageVersion);
    if (platform == null || installed == null) return null;
    return DesktopUpdateContext(platform: platform, installed: installed);
  }
}

void registerDesktopUpdate(GetIt getIt, DesktopUpdateContext context) {
  final env = getIt<EnvConfig>();
  getIt.registerLazySingleton<DesktopUpdateRepository>(
    () => DesktopUpdateRepositoryImpl(
      // Dio sans intercepteur d'authentification : la route est publique et
      // se lit avant la connexion.
      api: DesktopReleaseApi(createDioClient(env)),
      verifier: DesktopReleaseVerifier(
        platform: context.platform,
        channel: env.environment.label,
      ),
      downloader: DesktopUpdateDownloader(
        // Windows télécharge lui-même (certificats et proxy du système) ;
        // Linux passe par Dio.
        transfer: context.platform == DesktopPlatform.windows
            ? PowerShellInstallerTransfer()
            : DioInstallerTransfer(
                Dio(
                  BaseOptions(
                    connectTimeout: const Duration(seconds: 15),
                    receiveTimeout: AppConstants.desktopUpdateDownloadTimeout,
                  ),
                ),
              ),
        // Cache propre à l'utilisateur, et non `/tmp` partagé entre comptes.
        baseDirectory: getApplicationCacheDirectory,
      ),
      log: DesktopUpdateLog(baseDirectory: getApplicationCacheDirectory),
      installer: context.platform == DesktopPlatform.windows
          ? const WindowsDesktopInstaller()
          : LinuxDesktopInstaller(channel: env.environment.label),
    ),
  );
  getIt.registerLazySingleton<LastRunVersionStore>(
    () => SecureLastRunVersionStore(getIt<FlutterSecureStorage>()),
  );
}

/// Le cubit de la mise à jour, avec la synchronisation de l'instance globale
/// ([syncNow]) : avant d'installer, l'outbox part, au plus
/// [AppConstants.desktopUpdateOutboxDrainTimeout].
DesktopUpdateCubit createDesktopUpdateCubit(
  GetIt getIt,
  DesktopUpdateContext context, {
  required Future<void> Function() syncNow,
}) => DesktopUpdateCubit(
  repository: getIt<DesktopUpdateRepository>(),
  installed: context.installed,
  lastRun: getIt<LastRunVersionStore>(),
  // Toutes les 6 h, et à chaque retour du réseau : un poste allumé avant le
  // Wi-Fi de l'école ne doit pas attendre le top suivant.
  ticks: _merge([
    Stream<void>.periodic(AppConstants.desktopUpdateCheckInterval),
    getIt<ConnectivityService>().onStatusChange.where((online) => online),
  ]),
  exitApp: quitDesktopApp,
  pendingOperations: () async {
    try {
      await syncNow().timeout(AppConstants.desktopUpdateOutboxDrainTimeout);
    } catch (_) {
      // Délai dépassé ou cycle en échec : on compte ce qui reste.
    }
    // Les rejets en attente de décision comptent aussi : ils survivent à la
    // mise à jour, mais l'utilisateur doit savoir qu'ils sont là.
    final outbox = getIt<OutboxDao>();
    return await outbox.pendingCount() + await outbox.errorCount();
  },
);

/// Ferme l'application (après le lancement de l'installateur, ou « Quitter »
/// d'une mise à jour obligatoire).
void quitDesktopApp() => exit(0);

/// Les tops de plusieurs flux en un seul (sans dépendre du paquet `async`).
Stream<void> _merge(List<Stream<void>> streams) {
  final subscriptions = <StreamSubscription<void>>[];
  late final StreamController<void> controller;
  controller = StreamController<void>(
    onListen: () {
      for (final stream in streams) {
        subscriptions.add(stream.listen(controller.add, onError: (_) {}));
      }
    },
    onCancel: () async {
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    },
  );
  return controller.stream;
}
