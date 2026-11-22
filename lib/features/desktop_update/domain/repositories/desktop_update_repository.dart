import 'package:dartz/dartz.dart' show Either;
import 'package:school_app_flutter/core/error/failures.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/desktop_release.dart';

/// Annule un téléchargement en cours.
class DownloadCancellation {
  final List<void Function()> _listeners = [];
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  void onCancel(void Function() listener) {
    if (_cancelled) {
      listener();
    } else {
      _listeners.add(listener);
    }
  }
}

/// Le téléchargement a été annulé par l'utilisateur.
class DownloadCancelledFailure extends Failure {
  const DownloadCancelledFailure([super.message = 'Download cancelled']);
}

/// La fiche rendue par le back ne passe pas la vérification (signature,
/// plateforme, canal, lien) : on ne propose rien.
class UntrustedReleaseFailure extends Failure {
  const UntrustedReleaseFailure(super.message);
}

/// L'installateur n'a pas pu être lancé ou a échoué.
class InstallFailure extends Failure {
  const InstallFailure(super.message);
}

/// Un installateur téléchargé ET contrôlé, prêt à être lancé.
class VerifiedInstaller {
  final String path;
  final DesktopRelease release;

  const VerifiedInstaller({required this.path, required this.release});
}

abstract class DesktopUpdateRepository {
  /// La version proposée à un poste en [installed], ou `null` quand il n'y a
  /// rien à proposer (aucune version publiée, ou rien de plus récent).
  Future<Either<Failure, DesktopUpdateOffer?>> fetchOffer(AppVersion installed);

  /// Télécharge [release] et contrôle taille et empreinte. Un fichier déjà
  /// téléchargé et intact est réutilisé.
  Future<Either<Failure, VerifiedInstaller>> download(
    DesktopRelease release, {
    void Function(int received, int total)? onProgress,
    DownloadCancellation? cancellation,
  });

  /// Lance l'installation. En cas de succès, l'application doit se fermer :
  /// c'est l'installateur (ou l'appelant sous Linux) qui relance.
  Future<Either<Failure, void>> install(VerifiedInstaller installer);
}
