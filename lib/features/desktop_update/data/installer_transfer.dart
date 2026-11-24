import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:school_app_flutter/core/constants/app_constants.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_update_downloader.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/desktop_update_repository.dart';

/// Le transfert n'a pas abouti (réseau, TLS, proxy) ; [detail] garde la vraie
/// cause, pour le journal.
class DownloadTransferException implements Exception {
  final String detail;
  const DownloadTransferException(this.detail);

  @override
  String toString() => 'DownloadTransferException: $detail';
}

/// L'utilisateur a annulé le téléchargement.
class DownloadCancelledException implements Exception {
  const DownloadCancelledException();
}

/// Écrit le fichier désigné par une URL sur le disque. Le contrôle de taille
/// et d'empreinte reste à [DesktopUpdateDownloader] : un transfert ne décide
/// jamais qu'un fichier est bon.
abstract class InstallerTransfer {
  /// Écrit [url] dans [path]. Au-delà de [maxBytes], s'arrête et lève
  /// [DownloadIntegrityException]. [onProgress] reçoit les octets écrits.
  Future<void> fetch(
    Uri url,
    String path, {
    required int maxBytes,
    void Function(int received)? onProgress,
    DownloadCancellation? cancellation,
  });
}

/// Linux : Dio, dans le processus de l'application.
class DioInstallerTransfer implements InstallerTransfer {
  final Dio _dio;
  const DioInstallerTransfer(this._dio);

  static const _oversized = 'oversized';

  @override
  Future<void> fetch(
    Uri url,
    String path, {
    required int maxBytes,
    void Function(int received)? onProgress,
    DownloadCancellation? cancellation,
  }) async {
    final cancelToken = CancelToken();
    cancellation?.onCancel(() => cancelToken.cancel());
    try {
      await _dio.downloadUri(
        url,
        path,
        cancelToken: cancelToken,
        deleteOnError: true,
        onReceiveProgress: (received, _) {
          // Plus d'octets que la fiche signée n'en annonce : inutile d'aller
          // au bout, le contrôle échouera.
          if (received > maxBytes) {
            cancelToken.cancel(_oversized);
            return;
          }
          onProgress?.call(received);
        },
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e) && e.error == _oversized) {
        throw const DownloadIntegrityException('taille dépassée');
      }
      // Dio emballe aussi les erreurs d'écriture du fichier : c'est le disque,
      // pas le réseau.
      final cause = e.error;
      if (cause is FileSystemException) throw cause;
      rethrow;
    }
  }
}

/// Windows : le téléchargement passe par Windows lui-même (PowerShell,
/// `Net.WebClient`), comme le navigateur. Dart lit le magasin de certificats
/// une seule fois et n'y fait pas venir les racines que Windows télécharge
/// à la demande ; il ignore aussi le proxy du système. Sur un poste d'école
/// neuf, GitHub restait injoignable depuis l'application alors que le
/// navigateur l'atteignait.
class PowerShellInstallerTransfer implements InstallerTransfer {
  final Future<Process> Function(
    String executable,
    List<String> arguments,
    Map<String, String> environment,
  )
  _start;
  final Map<String, String> _environment;
  final Duration _pollInterval;

  PowerShellInstallerTransfer({
    Future<Process> Function(String, List<String>, Map<String, String>)? start,
    Map<String, String>? environment,
    Duration pollInterval = AppConstants.desktopUpdateProgressPollInterval,
  }) : _start = start ?? _systemStart,
       _environment = environment ?? Platform.environment,
       _pollInterval = pollInterval;

  static Future<Process> _systemStart(
    String executable,
    List<String> arguments,
    Map<String, String> environment,
  ) => Process.start(executable, arguments, environment: environment);

  /// Chemin complet, jamais résolu par le PATH.
  String get executable => p.windows.join(
    _environment['SystemRoot'] ?? r'C:\Windows',
    'System32',
    'WindowsPowerShell',
    'v1.0',
    'powershell.exe',
  );

  static const urlVariable = 'ETEELO_UPDATE_URL';
  static const outputVariable = 'ETEELO_UPDATE_OUT';

  /// L'URL et le chemin passent par l'environnement, jamais par le texte du
  /// script : aucun guillemet à échapper. TLS 1.2 (3072) est ajouté pour les
  /// .NET anciens ; le proxy du système s'identifie avec la session Windows.
  static const script =
      r"$ErrorActionPreference = 'Stop'; "
      r'[Net.ServicePointManager]::SecurityProtocol = '
      r'[Net.ServicePointManager]::SecurityProtocol -bor 3072; '
      r'$client = New-Object Net.WebClient; '
      r'if ($client.Proxy) { '
      r'$client.Proxy.Credentials = [Net.CredentialCache]::DefaultNetworkCredentials }; '
      r'$client.DownloadFile($env:ETEELO_UPDATE_URL, $env:ETEELO_UPDATE_OUT)';

  static const arguments = [
    '-NoProfile',
    '-NonInteractive',
    '-ExecutionPolicy',
    'Bypass',
    '-Command',
    script,
  ];

  @override
  Future<void> fetch(
    Uri url,
    String path, {
    required int maxBytes,
    void Function(int received)? onProgress,
    DownloadCancellation? cancellation,
  }) async {
    final Process process;
    try {
      process = await _start(executable, arguments, {
        urlVariable: url.toString(),
        outputVariable: path,
      });
    } on ProcessException catch (e) {
      throw DownloadTransferException('powershell introuvable : ${e.message}');
    }
    final stderr = process.stderr.transform(systemEncoding.decoder).join();
    unawaited(process.stdout.drain<void>());

    var cancelled = false;
    var oversized = false;
    cancellation?.onCancel(() {
      cancelled = true;
      process.kill();
    });
    final file = File(path);
    final poll = Timer.periodic(_pollInterval, (_) {
      final received = file.existsSync() ? file.lengthSync() : 0;
      if (received > maxBytes) {
        oversized = true;
        process.kill();
        return;
      }
      onProgress?.call(received);
    });

    final int exitCode;
    try {
      exitCode = await process.exitCode.timeout(
        AppConstants.desktopUpdateDownloadTimeout,
        onTimeout: () {
          process.kill();
          return -1;
        },
      );
    } finally {
      poll.cancel();
    }
    final error = (await stderr).trim();

    if (cancelled) throw const DownloadCancelledException();
    if (oversized) throw const DownloadIntegrityException('taille dépassée');
    if (exitCode != 0) {
      throw DownloadTransferException(
        exitCode == -1
            ? 'délai dépassé'
            : 'powershell ($exitCode) : ${error.isEmpty ? '—' : error}',
      );
    }
    onProgress?.call(file.existsSync() ? file.lengthSync() : 0);
  }
}
