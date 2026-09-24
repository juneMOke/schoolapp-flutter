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

  /// « Tél. Promoteur : » — le téléphone de l'ÉTABLISSEMENT, en en-tête.
  ///
  /// Il s'imprimait nu jusqu'ici, comme les autres lignes d'école. Il prend un
  /// libellé le jour où un SECOND numéro entre dans l'en-tête : deux numéros
  /// sans nom ne valent pas mieux qu'aucun.
  final String schoolPhoneLabel;

  /// « Tél. caisse : » — le numéro que la famille appelle pour une question de
  /// paiement (`ref_school.till_phone`, v50).
  ///
  /// ⚠️ Même libellé que celui que le SERVEUR imprime sur le reçu scellé, où il
  /// figure dans le bloc du montant. Les deux papiers finissent dans les mains
  /// du même parent : deux noms pour un même numéro lui feraient chercher la
  /// différence entre eux.
  final String tillPhoneLabel;

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

  /// « Solde restant à payer pour ce(s) frais » — le TITRE du bloc, qui coiffe
  /// le détail comme « Répartition » coiffe le sien.
  ///
  /// Le titre nomme le PÉRIMÈTRE, et c'est ce qu'il devait faire : le bloc ne
  /// porte que les frais que CE versement a réglés, jamais toute la dette de
  /// l'élève — un parent venu payer les frais divers ne doit pas y lire le solde
  /// de son minerval.
  ///
  /// ⚠️ **Le qualificatif de TEMPS a disparu avec l'ancien libellé** (« …au
  /// moment de l'impression », arbitré par le user le 2026-09-24). C'était le
  /// seul endroit de la pièce qui disait que ce chiffre est un instantané, que
  /// la synchro peut déplacer. Le solde s'imprime donc désormais sans réserve,
  /// comme le montant reçu et la répartition — à rouvrir avec le porteur, pas
  /// à rétablir en douce.
  final String balanceLabel;

  /// « Total » — la dernière ligne du bloc, sous le filet.
  final String balanceTotalLabel;

  /// « Historique des paiements » — le TITRE du bloc de pied, qui liste les
  /// versements de l'élève sur l'année, **celui de ce ticket compris**.
  ///
  /// Le versement du jour y a sa ligne, datée comme les autres et sans mention
  /// particulière : c'est ce qui fait du total du bloc un CUMUL D'ANNÉE plutôt
  /// qu'un sous-total arrêté la veille.
  final String historyLabel;

  /// « Total versé » — la dernière ligne du bloc d'historique, sous le filet.
  /// C'est le **cumul de l'année, ce versement compris**.
  ///
  /// Distinct de [balanceTotalLabel] bien que les deux puissent s'écrire
  /// « Total » : l'un totalise ce qui RESTE, l'autre ce qui a été VERSÉ. Deux
  /// totaux voisins sur le même papier doivent se distinguer par leur libellé,
  /// faute de quoi le parent lit deux fois la même nature de nombre.
  final String historyTotalLabel;

  /// « Conservez ce ticket jusqu'à la remise de votre reçu définitif. »
  ///
  /// ⚠️ **Imprimée seulement sur une pièce NON scellée.** Sur un ticket qui
  /// porte déjà son numéro définitif, elle est factuellement fausse : il n'y a
  /// pas de reçu à venir, celui-là l'est. Sa raison d'être (RG-012-12, le levier
  /// de rappel de l'établissement) ne vaut que hors ligne.
  final String keepTicketNotice;

  /// « Signature du caissier » — coiffe la zone à signer, en pied de pièce.
  ///
  /// C'est le CAISSIER qui signe, pas le payeur : sur un papier que le parent
  /// emporte, la signature du parent ne prouverait rien à l'école — elle ne
  /// vaudrait que contre une souche, et la thermique n'en produit aucune.
  /// Celle du caissier, elle, contresigne à la main le nom déjà imprimé en
  /// zone de traçabilité (RG-012-11 : sur une pièce non scellée, l'imputabilité
  /// est humaine).
  ///
  /// ⚠️ **Libellé vide ⇒ la zone entière disparaît**, blancs et trait compris.
  /// Un trait à signer sans rien qui dise qui signe ne se remplit pas, et deux
  /// lignes blanches inexpliquées se lisent comme un défaut d'impression.
  final String signatureLabel;

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
    required this.schoolPhoneLabel,
    required this.tillPhoneLabel,
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
    required this.historyLabel,
    required this.historyTotalLabel,
    required this.signatureLabel,
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
    schoolPhoneLabel,
    tillPhoneLabel,
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
    historyLabel,
    historyTotalLabel,
    signatureLabel,
    keepTicketNotice,
    thanksNotice,
    editorNotice,
    editorSite,
  ];
}
