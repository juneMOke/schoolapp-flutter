/// Le poste sait-il poser une photo ? Oui partout : sur le web, le magasin
/// scelle dans IndexedDB (`platformBlobFiles`) et le viseur passe par
/// `camera_web` ; sur Windows et Linux, par `camera_desktop`.
bool get photoCaptureSupported => true;
