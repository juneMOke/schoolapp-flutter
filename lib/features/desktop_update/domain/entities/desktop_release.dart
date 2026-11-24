import 'package:equatable/equatable.dart';
import 'package:school_app_flutter/features/desktop_update/domain/entities/app_version.dart';

/// Les deux plateformes de bureau livrées.
enum DesktopPlatform {
  windows('windows'),
  linux('linux');

  final String wire;
  const DesktopPlatform(this.wire);
}

/// Une version publiée, telle que la CI l'a SIGNÉE : chaque champ vient de
/// `signedPayload`, jamais du JSON d'à côté (contrat back, règle 1).
class DesktopRelease extends Equatable {
  final AppVersion version;
  final DesktopPlatform platform;
  final String channel;
  final Uri url;

  /// SHA-256 du fichier, 64 caractères hexadécimaux minuscules.
  final String sha256;

  /// Taille du fichier en octets.
  final int size;
  final String notesFr;
  final String notesEn;

  const DesktopRelease({
    required this.version,
    required this.platform,
    required this.channel,
    required this.url,
    required this.sha256,
    required this.size,
    required this.notesFr,
    required this.notesEn,
  });

  /// Le nom du fichier, dernier segment du lien.
  String get fileName => url.pathSegments.last;

  @override
  List<Object?> get props => [
    version,
    platform,
    channel,
    url,
    sha256,
    size,
    notesFr,
    notesEn,
  ];
}

/// Les notes d'une version, pour l'affichage seulement (non signées).
class DesktopReleaseNotes extends Equatable {
  final AppVersion version;
  final String notesFr;
  final String notesEn;

  const DesktopReleaseNotes({
    required this.version,
    required this.notesFr,
    required this.notesEn,
  });

  @override
  List<Object?> get props => [version, notesFr, notesEn];
}

/// Ce que le back propose à un poste en [installed].
class DesktopUpdateOffer extends Equatable {
  final AppVersion installed;
  final DesktopRelease release;
  final AppVersion? minimumSupported;

  /// Notes des versions manquées, de la plus haute à la plus basse (10 au
  /// plus) ; vide si le back n'en rend pas.
  final List<DesktopReleaseNotes> notesSince;

  const DesktopUpdateOffer({
    required this.installed,
    required this.release,
    required this.minimumSupported,
    this.notesSince = const [],
  });

  /// Le poste est sous la version minimale du canal : il doit se mettre à
  /// jour pour continuer.
  bool get mandatory {
    final minimum = minimumSupported;
    return minimum != null && installed < minimum;
  }

  @override
  List<Object?> get props => [installed, release, minimumSupported, notesSince];
}
