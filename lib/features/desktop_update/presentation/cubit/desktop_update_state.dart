import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/desktop_release.dart';

enum DesktopUpdateStatus {
  /// Rien à proposer (ou pas encore vérifié).
  idle,

  /// Une version plus récente est proposée.
  available,

  /// Synchronisation de l'outbox avant d'installer.
  preparing,

  /// Il reste des opérations non envoyées : l'utilisateur confirme.
  confirmPending,
  downloading,

  /// L'installateur est lancé ; l'application va se fermer.
  installing,
  failed,
}

/// Pourquoi la mise à jour a échoué — chaque cas a son message.
enum DesktopUpdateError { network, integrity, install, storage, unknown }

class DesktopUpdateState extends Equatable {
  final DesktopUpdateStatus status;
  final DesktopUpdateOffer? offer;

  /// « Plus tard » : la fenêtre ne revient pas avant le prochain démarrage ;
  /// la pastille du menu du compte reste.
  final bool dismissed;

  /// Nombre d'opérations encore dans l'outbox ([DesktopUpdateStatus.confirmPending]).
  final int pendingOperations;

  /// Avancement du téléchargement, de 0 à 1.
  final double progress;
  final DesktopUpdateError? error;

  /// La version vient d'être installée (premier lancement après une mise à
  /// jour) : annoncé une fois.
  final AppVersion? justUpdatedTo;

  /// L'utilisateur a demandé la fenêtre (menu du compte) : elle s'ouvre même
  /// hors de l'accueil, puisque c'est lui qui interrompt sa saisie.
  final bool requested;

  const DesktopUpdateState({
    this.status = DesktopUpdateStatus.idle,
    this.offer,
    this.dismissed = false,
    this.pendingOperations = 0,
    this.progress = 0,
    this.error,
    this.justUpdatedTo,
    this.requested = false,
  });

  bool get mandatory => offer?.mandatory ?? false;

  /// Une version est proposée (la pastille du menu se montre).
  bool get hasOffer => offer != null;

  /// La fenêtre doit être ouverte : une offre en cours de traitement, ou une
  /// offre que l'utilisateur n'a pas remise à plus tard.
  bool get wantsDialog =>
      offer != null &&
      (status != DesktopUpdateStatus.available || !dismissed || mandatory);

  /// Un geste est en cours : ni nouvelle vérification, ni fermeture.
  bool get busy =>
      status == DesktopUpdateStatus.preparing ||
      status == DesktopUpdateStatus.downloading ||
      status == DesktopUpdateStatus.installing;

  DesktopUpdateState copyWith({
    DesktopUpdateStatus? status,
    Object? offer = _keep,
    bool? dismissed,
    int? pendingOperations,
    double? progress,
    Object? error = _keep,
    Object? justUpdatedTo = _keep,
    bool? requested,
  }) => DesktopUpdateState(
    status: status ?? this.status,
    offer: identical(offer, _keep) ? this.offer : offer as DesktopUpdateOffer?,
    dismissed: dismissed ?? this.dismissed,
    pendingOperations: pendingOperations ?? this.pendingOperations,
    progress: progress ?? this.progress,
    error: identical(error, _keep) ? this.error : error as DesktopUpdateError?,
    justUpdatedTo: identical(justUpdatedTo, _keep)
        ? this.justUpdatedTo
        : justUpdatedTo as AppVersion?,
    requested: requested ?? this.requested,
  );

  @override
  List<Object?> get props => [
    status,
    offer,
    dismissed,
    pendingOperations,
    progress,
    error,
    justUpdatedTo,
    requested,
  ];
}

const _keep = Object();
