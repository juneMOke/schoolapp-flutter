import 'package:equatable/equatable.dart';

/// Combien de messages partiraient — un par couple (tuteur, élève).
///
/// « Joignable » veut dire : numéro au format E.164 valide. Ce n'est pas la
/// preuve d'un compte WhatsApp ; la remise réelle se suit côté serveur.
class AnnouncementReach extends Equatable {
  final int students;
  final int guardians;
  final int messages;
  final int reachableMessages;
  final int guardiansWithoutPhone;
  final int studentsUnreachable;

  /// `false` tant que la plateforme n'a pas activé le gabarit WhatsApp de
  /// l'école : brouillons et modèles restent possibles, l'envoi non. `null`
  /// sur la portée figée d'un communiqué envoyé, qui ne le dit pas.
  final bool? whatsappEnabled;

  const AnnouncementReach({
    required this.students,
    required this.guardians,
    required this.messages,
    required this.reachableMessages,
    required this.guardiansWithoutPhone,
    required this.studentsUnreachable,
    this.whatsappEnabled,
  });

  /// Les messages qui ne partiront pas, faute de numéro valide.
  int get unreachableMessages => messages - reachableMessages;

  @override
  List<Object?> get props => [
    students,
    guardians,
    messages,
    reachableMessages,
    guardiansWithoutPhone,
    studentsUnreachable,
    whatsappEnabled,
  ];
}
