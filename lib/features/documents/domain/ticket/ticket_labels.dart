import 'package:equatable/equatable.dart';

/// Libellés fixes du ticket, injectés depuis `AppLocalizations`.
///
/// Le modèle et son rendu restent **purs** — aucun `BuildContext`, aucune
/// dépendance Flutter — tout en respectant l'interdiction des chaînes en dur :
/// c'est l'appelant qui traduit, le gabarit qui arrange.
class TicketLabels extends Equatable {
  /// Nature de la pièce, imprimée en tête : « Ticket de perception ».
  ///
  /// ⚠️ **Distinct de la « note de perception »** (`EditiqueDocumentType.NP`),
  /// qui est une pièce **annuelle scellée** au niveau élève. Deux objets
  /// différents : celui-ci atteste **le montant reçu** lors d'un encaissement,
  /// trop-perçu ou non — l'imputation exacte appartient au reçu scellé.
  final String documentTitle;

  /// La mention discrète du cas NON scellé, posée en fin de libellé de
  /// référence : « Réf. provisoire `<numéro>` ».
  ///
  /// Ce n'est plus un bandeau. Le bandeau pleine largeur a disparu avec la
  /// décision de rendre le ticket officiel dès qu'il porte un numéro définitif ;
  /// ce champ nomme donc désormais une MENTION, et son nom suit.
  ///
  /// Le mot est accolé au libellé et non ajouté en fin de ligne, pour deux
  /// raisons. Il qualifie ainsi le NUMÉRO — l'argent, lui, est reçu, et le
  /// ticket l'affirme — là où un mot flottant qualifierait le versement. Et il
  /// se replie proprement : mis entre parenthèses en fin de ligne, il se coupait
  /// en deux quand la référence retombe sur l'UUID du paiement.
  final String provisionalMention;
  final String referenceLabel;

  /// « Date : » — coiffe la date de versement, l'heure restant calée à droite
  /// sur la même ligne. Aucune ligne de papier ajoutée : à 48 colonnes il reste
  /// 27 caractères de battement, et 11 à 32 colonnes.
  final String dateLabel;

  final String cashierLabel;

  /// « PAYEUR : » — en tête du bloc payeur, quand il y en a un.
  final String payerLabel;

  /// « Tél. » — le numéro du payeur. Seul, il suffit à garder le bloc.
  final String phoneLabel;

  final String studentLabel;
  final String matriculationLabel;
  final String classroomLabel;
  final String amountReceivedLabel;

  /// « Taux » — imprimé **seulement** quand perçu et imputé ne sont pas dans la
  /// même unité. C'est le chiffre que le parent conteste au guichet ; le laisser
  /// déduire par division ferait apparaître un taux dérivé de l'arrondi
  /// (2 847,3 là où le caissier a annoncé 2 850), ce qui fait amateur.
  final String rateLabel;

  /// « soit » — coiffe la valeur d'un poste **en devise reçue**, sous son
  /// montant imputé. Sans ce mot, une seconde ligne de chiffres sous la première
  /// se lirait comme un second montant dû.
  final String derivedAmountPrefix;

  final String allocationsLabel;

  /// Part du montant reçu qu'aucune créance n'absorbe — imprimée comme dernière
  /// ligne de la répartition, et seulement quand elle est strictement positive.
  ///
  /// Le ticket **atteste le montant perçu**, il n'arbitre pas son imputation :
  /// c'est le reçu scellé qui fait apparaître le trop-perçu. Ce libellé n'est là
  /// que pour empêcher un écart muet entre le reçu et la ventilation.
  final String advanceLabel;

  /// « Solde au moment de l'impression » — le TITRE du bloc, qui coiffe le
  /// détail comme « Répartition » coiffe le sien.
  ///
  /// Le qualificatif de temps est DANS le titre, et n'a plus de ligne à lui :
  /// il se lit avant les chiffres au lieu de les suivre, et une réserve posée
  /// sous le total se lisait comme une incertitude sur le total seul.
  final String balanceLabel;

  /// « Total » — la dernière ligne du bloc, sous le filet.
  final String balanceTotalLabel;

  /// « Conservez ce ticket jusqu'à la remise de votre reçu définitif. »
  ///
  /// ⚠️ **Imprimée seulement sur une pièce NON scellée.** Sur un ticket qui
  /// porte déjà son numéro définitif, elle est factuellement fausse : il n'y a
  /// pas de reçu à venir, celui-là l'est. Sa raison d'être (RG-012-12, le levier
  /// de rappel de l'établissement) ne vaut que hors ligne.
  final String keepTicketNotice;

  /// « Nous vous remercions pour votre confiance. »
  final String thanksNotice;

  /// « Reçu édité par ETEELO CONNECT » — l'éditeur du logiciel, en pied.
  final String editorNotice;

  /// « eteeloconnect.com » — **sans schéma**. C'est l'usage sur un reçu, ça
  /// économise la largeur, et ça n'imprime pas un `http://` sur un papier que
  /// des familles gardent.
  final String editorSite;

  const TicketLabels({
    required this.documentTitle,
    required this.provisionalMention,
    required this.referenceLabel,
    required this.dateLabel,
    required this.cashierLabel,
    required this.payerLabel,
    required this.phoneLabel,
    required this.studentLabel,
    required this.matriculationLabel,
    required this.classroomLabel,
    required this.amountReceivedLabel,
    required this.rateLabel,
    required this.derivedAmountPrefix,
    required this.allocationsLabel,
    required this.advanceLabel,
    required this.balanceLabel,
    required this.balanceTotalLabel,
    required this.keepTicketNotice,
    required this.thanksNotice,
    required this.editorNotice,
    required this.editorSite,
  });

  @override
  List<Object?> get props => [
    documentTitle,
    provisionalMention,
    referenceLabel,
    dateLabel,
    cashierLabel,
    payerLabel,
    phoneLabel,
    studentLabel,
    matriculationLabel,
    classroomLabel,
    amountReceivedLabel,
    rateLabel,
    derivedAmountPrefix,
    allocationsLabel,
    advanceLabel,
    balanceLabel,
    balanceTotalLabel,
    keepTicketNotice,
    thanksNotice,
    editorNotice,
    editorSite,
  ];
}
