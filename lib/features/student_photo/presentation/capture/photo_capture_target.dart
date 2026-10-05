/// Ce que devient la photo validée : enregistrée pour un élève qui existe, ou
/// rendue en brouillon à une nouvelle inscription (l'élève n'existe pas
/// encore sur le poste).
sealed class PhotoCaptureTarget {
  const PhotoCaptureTarget();
}

class SaveForStudent extends PhotoCaptureTarget {
  final String studentId;

  const SaveForStudent(this.studentId);
}

class KeepAsDraft extends PhotoCaptureTarget {
  const KeepAsDraft();
}
