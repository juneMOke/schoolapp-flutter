/// Mémorise la dernière version lancée, pour annoncer « Mis à jour en X ».
abstract class LastRunVersionStore {
  Future<String?> read();
  Future<void> write(String version);
}
