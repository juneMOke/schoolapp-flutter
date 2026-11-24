import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:dio/dio.dart';
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/core/network/api_error_parser.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_installer.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_release_api.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_release_verifier.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_update_downloader.dart';
import 'package:school_app_flutter/features/desktop_update/data/desktop_update_log.dart';
import 'package:school_app_flutter/features/desktop_update/data/installer_transfer.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/desktop_release.dart';
import 'package:school_app_flutter/features/desktop_update/domain/repositories/desktop_update_repository.dart';

class DesktopUpdateRepositoryImpl implements DesktopUpdateRepository {
  final DesktopReleaseApi _api;
  final DesktopReleaseVerifier _verifier;
  final DesktopUpdateDownloader _downloader;
  final DesktopInstaller _installer;
  final DesktopUpdateLog? _log;

  DesktopUpdateRepositoryImpl({
    required DesktopReleaseApi api,
    required DesktopReleaseVerifier verifier,
    required DesktopUpdateDownloader downloader,
    required DesktopInstaller installer,
    DesktopUpdateLog? log,
  }) : _api = api,
       _verifier = verifier,
       _downloader = downloader,
       _installer = installer,
       _log = log;

  @override
  Future<Either<Failure, DesktopUpdateOffer?>> fetchOffer(
    AppVersion installed,
  ) async {
    final DesktopLatestWire? wire;
    try {
      wire = await _api.latest(platform: _verifier.platform, since: installed);
    } on DioException catch (e) {
      return Left(ApiErrorParser.failureOf(e));
    } on FormatException catch (e) {
      return Left(ServerFailure(e.message));
    }
    if (wire == null) return const Right(null);

    final DesktopRelease release;
    try {
      release = await _verifier.verify(
        signedPayload: wire.signedPayload,
        signature: wire.signature,
      );
    } on FormatException catch (e) {
      return Left(UntrustedReleaseFailure(e.message));
    }
    // Jamais de descente, même si la fiche le dit : une base migrée ne revient
    // pas en arrière.
    if (!(release.version > installed)) return const Right(null);

    final minimum = AppVersion.tryParseStrict(wire.minimumSupported);
    return Right(
      DesktopUpdateOffer(
        installed: installed,
        release: release,
        // Un minimum au-dessus de la version proposée ne s'atteindrait pas :
        // le back le refuse, le poste ne le croit pas davantage.
        minimumSupported: minimum != null && minimum > release.version
            ? null
            : minimum,
        notesSince: [
          for (final notes in wire.notesSince)
            if (notes.version > installed && !(notes.version > release.version))
              notes,
        ],
      ),
    );
  }

  @override
  Future<Either<Failure, VerifiedInstaller>> download(
    DesktopRelease release, {
    void Function(int received, int total)? onProgress,
    DownloadCancellation? cancellation,
  }) async {
    try {
      final path = await _downloader.download(
        release,
        onProgress: onProgress,
        cancellation: cancellation,
      );
      return Right(VerifiedInstaller(path: path, release: release));
    } on DownloadCancelledException {
      return const Left(DownloadCancelledFailure());
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return const Left(DownloadCancelledFailure());
      }
      await _record(release, e);
      return Left(ApiErrorParser.failureOf(e));
    } on DownloadTransferException catch (e) {
      await _record(release, e.detail);
      return Left(NetworkFailure(e.detail));
    } on DownloadIntegrityException catch (e) {
      await _record(release, e);
      return Left(IntegrityFailure(e.reason));
    } catch (e) {
      await _record(release, e);
      return Left(StorageFailure(e.toString()));
    }
  }

  Future<void> _record(DesktopRelease release, Object cause) async =>
      _log?.record('téléchargement ${release.version} (${release.url})', cause);

  @override
  Future<Either<Failure, bool>> install(VerifiedInstaller installer) async {
    try {
      await _installer.install(installer);
      return Right(_installer.appMustQuit);
    } on DesktopInstallException catch (e) {
      await _log?.record('installation ${installer.release.version}', e);
      return Left(InstallFailure(e.message));
    } catch (e) {
      await _log?.record('installation ${installer.release.version}', e);
      return Left(InstallFailure(e.toString()));
    }
  }
}
