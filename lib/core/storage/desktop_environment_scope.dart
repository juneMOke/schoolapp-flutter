import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:school_app_flutter/core/config/app_environment.dart';
import 'package:school_app_flutter/core/constants/app_constants.dart';

/// Environnement à isoler sur ce poste, ou `null` s'il n'y a rien à isoler.
///
/// Sur la tablette, chaque flavor est une application distincte : son
/// trousseau et ses dossiers lui appartiennent déjà. Le poste de bureau n'a
/// qu'un exécutable par plateforme, et le greffon de stockage sécurisé range
/// TOUTES ses entrées sous l'identifiant de l'application (Linux : un seul
/// secret libsecret ; Windows : un seul fichier DPAPI dans le dossier de
/// support). Staging et production partageaient donc jeton de session, clés
/// de base, préférences — et la mémoire de la dernière version lancée.
///
/// La production n'est JAMAIS isolée : elle garde ses entrées et ses dossiers
/// tels qu'ils sont, à l'octet près. Renommer une de ses clés rendrait sa base
/// illisible (la clé SQLCipher ne serait plus trouvée).
String? desktopIsolatedEnvironment({
  TargetPlatform? platform,
  String? environment,
}) {
  if (kIsWeb) return null;
  final target = platform ?? defaultTargetPlatform;
  if (target != TargetPlatform.windows && target != TargetPlatform.linux) {
    return null;
  }
  final resolved = AppEnvironment.fromName(
    environment ??
        const String.fromEnvironment(
          AppConstants.appEnvironmentDefineKey,
          defaultValue: AppConstants.defaultAppEnvironment,
        ),
  );
  return resolved == AppEnvironment.prod ? null : resolved.label;
}

/// Dossier de base des magasins d'octets chiffrés (photos, éditique,
/// documents du personnel, programme de cours).
///
/// Production et tablette : le dossier de support, comme toujours. Poste hors
/// production : un sous-dossier `environments/<env>`. Sans lui, la staging
/// — qui ne trouve plus la clé de la production — constaterait une clé neuve
/// et effacerait le répertoire, c'est-à-dire les pièces de la production.
Future<String> blobBaseDirectoryPath({
  required Future<String> Function() supportDirectory,
  String? isolatedEnvironment,
}) async {
  final base = await supportDirectory();
  return isolatedEnvironment == null
      ? base
      : p.join(
          base,
          AppConstants.desktopEnvironmentsDirectoryName,
          isolatedEnvironment,
        );
}

/// [blobBaseDirectoryPath] pour ce poste.
Future<String> defaultBlobBaseDirectoryPath() => blobBaseDirectoryPath(
  supportDirectory: () async => (await getApplicationSupportDirectory()).path,
  isolatedEnvironment: desktopIsolatedEnvironment(),
);
