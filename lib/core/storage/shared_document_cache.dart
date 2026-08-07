import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Efface les pièces déposées **en clair** par le partage système.
///
/// `Printing.sharePdf` n'est pas un partage en mémoire : le plugin écrit le PDF
/// dans `cacheDir/share/<nom>.pdf` et **ne l'efface jamais**. Un reçu de
/// paiement, une note de perception ou un relevé de compte y séjournent donc en
/// clair, hors de la base SQLCipher — exactement ce que l'ADR-012 D-7 interdit
/// (« effacement physique, pas un filtre de lecture ») et ce que son point
/// ouvert PO-5 signale.
///
/// La purge est branchée sur la **fin de session**, seul moment où l'on sait
/// que les pièces du compte sortant n'ont plus à être accessibles. Elle est
/// délibérément **best-effort** : un échec d'entrée-sortie ne doit jamais
/// empêcher une déconnexion ni une révocation de session d'aboutir — on
/// préfère un fichier résiduel à une session qu'on n'arrive plus à fermer.
class SharedDocumentCache {
  /// Sous-dossier du cache utilisé par le plugin `printing`.
  static const String _shareDirectoryName = 'share';

  /// Injectable pour les tests : résout le répertoire temporaire de la
  /// plateforme (`getCacheDir()` sur Android).
  final Future<Directory> Function() _temporaryDirectory;

  const SharedDocumentCache({Future<Directory> Function()? temporaryDirectory})
    : _temporaryDirectory = temporaryDirectory ?? getTemporaryDirectory;

  /// Supprime le dossier de partage et tout son contenu.
  ///
  /// Ne lève jamais. Renvoie `true` si le dossier n'existe plus à la sortie —
  /// utile aux tests et aux diagnostics, jamais consulté par les appelants.
  Future<bool> purge() async {
    try {
      final tmp = await _temporaryDirectory();
      final shareDir = Directory(p.join(tmp.path, _shareDirectoryName));
      if (await shareDir.exists()) {
        await shareDir.delete(recursive: true);
      }
      return !await shareDir.exists();
    } catch (_) {
      // Cache indisponible, permission refusée, canal de plateforme absent
      // (tests, binaire antérieur au plugin) : sans conséquence ici.
      return false;
    }
  }
}
